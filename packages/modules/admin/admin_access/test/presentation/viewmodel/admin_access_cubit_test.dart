import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_access/src/domain/entity/admin_access_entity.dart';
import 'package:admin_access/src/presentation/viewmodel/admin_access_cubit.dart';

import '../../admin_access_mock_definitions.dart';

void main() {
  late MockAdminAccessRepository repository;
  late MockAuthPublicApi authApi;
  late MockCrashlyticsService crashlytics;
  late StreamController<AdminAccessEntity> accessController;

  const signedOut = AdminAccessEntity(status: .signedOut);
  const unauthorized = AdminAccessEntity(status: .unauthorized, userId: 'u1', email: 'user@example.com');
  const authorized = AdminAccessEntity(status: .authorized, userId: 'a1', email: 'admin@example.com');

  AdminAccessCubit buildCubit() =>
      AdminAccessCubit(adminAccessRepository: repository, authApi: authApi, crashlyticsService: crashlytics);

  void verifyErrorRecorded() => verify(
    () => crashlytics.recordError(
      exception: any(named: 'exception'),
      stackTrace: any(named: 'stackTrace'),
      reason: any(named: 'reason'),
    ),
  ).called(1);

  setUp(() {
    repository = MockAdminAccessRepository();
    authApi = MockAuthPublicApi();
    crashlytics = MockCrashlyticsService();
    accessController = StreamController<AdminAccessEntity>.broadcast();
    when(() => repository.watchAccess()).thenAnswer((_) => accessController.stream);
  });

  tearDown(() => accessController.close());

  blocTest<AdminAccessCubit, AdminAccessState>(
    'maps access changes to states',
    build: buildCubit,
    act: (cubit) async {
      cubit.start();
      accessController
        ..add(signedOut)
        ..add(unauthorized)
        ..add(authorized);
    },
    expect: () => const [
      AdminAccessState.signedOut(),
      AdminAccessState.unauthorized(email: 'user@example.com'),
      AdminAccessState.authorized(userId: 'a1', email: 'admin@example.com'),
    ],
  );

  blocTest<AdminAccessCubit, AdminAccessState>(
    'emits error and records it when the access stream fails',
    build: buildCubit,
    act: (cubit) {
      cubit.start();
      accessController.addError(Exception('offline'));
    },
    expect: () => const [AdminAccessState.error()],
    verify: (_) => verifyErrorRecorded(),
  );

  blocTest<AdminAccessCubit, AdminAccessState>(
    'signIn trims the email and waits for the access stream',
    setUp: () =>
        when(() => authApi.signInWithEmailAndPassword(email: 'admin@example.com', password: 'secret'))
            .thenAnswer((_) async => 'a1'),
    build: buildCubit,
    act: (cubit) async {
      cubit.start();
      await cubit.signIn(email: ' admin@example.com ', password: 'secret');
      accessController.add(authorized);
    },
    expect: () => const [
      AdminAccessState.signingIn(),
      AdminAccessState.authorized(userId: 'a1', email: 'admin@example.com'),
    ],
  );

  blocTest<AdminAccessCubit, AdminAccessState>(
    'a failed signIn keeps its message until the next attempt',
    setUp: () => when(
      () => authApi.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('wrong password')),
    build: buildCubit,
    act: (cubit) async {
      cubit.start();
      await cubit.signIn(email: 'admin@example.com', password: 'nope');
      accessController.add(signedOut);
    },
    expect: () => const [AdminAccessState.signingIn(), AdminAccessState.signedOut(signInFailed: true)],
    verify: (_) => verifyErrorRecorded(),
  );

  blocTest<AdminAccessCubit, AdminAccessState>(
    'recheck picks up a newly granted claim',
    setUp: () => when(() => repository.refreshAccess()).thenAnswer((_) async => authorized),
    build: buildCubit,
    seed: () => const AdminAccessState.unauthorized(email: 'admin@example.com'),
    act: (cubit) => cubit.recheck(),
    expect: () => const [
      AdminAccessState.checking(),
      AdminAccessState.authorized(userId: 'a1', email: 'admin@example.com'),
    ],
  );

  blocTest<AdminAccessCubit, AdminAccessState>(
    'recheck emits error and records it on failure',
    setUp: () => when(() => repository.refreshAccess()).thenThrow(Exception('offline')),
    build: buildCubit,
    act: (cubit) => cubit.recheck(),
    expect: () => const [AdminAccessState.checking(), AdminAccessState.error()],
    verify: (_) => verifyErrorRecorded(),
  );

  test('signOut delegates to the auth API', () async {
    when(() => authApi.signOut()).thenAnswer((_) async {});
    final cubit = buildCubit();
    await cubit.signOut();
    verify(() => authApi.signOut()).called(1);
    await cubit.close();
  });

  test('close cancels the access subscription', () async {
    final cubit = buildCubit()..start();
    expect(accessController.hasListener, isTrue);
    await cubit.close();
    expect(accessController.hasListener, isFalse);
  });
}
