import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:profile/src/domain/service/profile_auth_port.dart';
import 'package:profile/src/domain/usecase/delete_profile_use_case.dart';
import 'package:profile/src/presentation/viewmodel/delete_profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../profile_mock_definitions.dart';

void main() {
  late MockDeleteProfileUseCase deleteProfileUseCase;
  late MockCrashlyticsService crashlyticsService;

  DeleteProfileCubit buildCubit() {
    return DeleteProfileCubit(
      deleteProfileUseCase: deleteProfileUseCase,
      crashlyticsService: crashlyticsService,
    );
  }

  setUpAll(() => registerFallbackValue(ReauthProvider.google));

  setUp(() {
    deleteProfileUseCase = MockDeleteProfileUseCase();
    crashlyticsService = MockCrashlyticsService();

    when(
      () => crashlyticsService.recordError(
        exception: any(named: 'exception'),
        stackTrace: any(named: 'stackTrace'),
        reason: any(named: 'reason'),
      ),
    ).thenReturn(null);
  });

  group('DeleteProfileCubit.deleteProfile', () {
    blocTest<DeleteProfileCubit, DeleteProfileState>(
      'emits loading then completed when use case completes',
      build: buildCubit,
      setUp: () {
        when(() => deleteProfileUseCase.execute())
            .thenAnswer((_) async => DeleteProfileResult.completed);
      },
      act: (cubit) => cubit.deleteProfile(),
      expect: () => [
        const DeleteProfileState.loading(),
        const DeleteProfileState.completed(),
      ],
      verify: (_) {
        verify(() => deleteProfileUseCase.execute()).called(1);
        verifyNever(
          () => crashlyticsService.recordError(
            exception: any(named: 'exception'),
            stackTrace: any(named: 'stackTrace'),
            reason: any(named: 'reason'),
          ),
        );
      },
    );

    blocTest<DeleteProfileCubit, DeleteProfileState>(
      'emits loading then authRequired when use case requires re-auth',
      build: buildCubit,
      setUp: () {
        when(() => deleteProfileUseCase.execute())
            .thenAnswer((_) async => DeleteProfileResult.authRequired);
      },
      act: (cubit) => cubit.deleteProfile(),
      expect: () => [
        const DeleteProfileState.loading(),
        const DeleteProfileState.authRequired(),
      ],
      verify: (_) {
        verify(() => deleteProfileUseCase.execute()).called(1);
        verifyNever(
          () => crashlyticsService.recordError(
            exception: any(named: 'exception'),
            stackTrace: any(named: 'stackTrace'),
            reason: any(named: 'reason'),
          ),
        );
      },
    );

    blocTest<DeleteProfileCubit, DeleteProfileState>(
      'emits loading then error and records crashlytics when use case throws',
      build: buildCubit,
      setUp: () {
        when(() => deleteProfileUseCase.execute())
            .thenThrow(Exception('delete failed'));
      },
      act: (cubit) => cubit.deleteProfile(),
      expect: () => [
        const DeleteProfileState.loading(),
        const DeleteProfileState.error(),
      ],
      verify: (_) {
        verify(() => deleteProfileUseCase.execute()).called(1);
        verify(
          () => crashlyticsService.recordError(
            exception: any(named: 'exception'),
            stackTrace: any(named: 'stackTrace'),
            reason: 'Unable to delete user profile!',
          ),
        ).called(1);
      },
    );
  });

  group('DeleteProfileCubit.reauthenticateAndDelete', () {
    void stubResult(DeleteProfileResult result) => when(
      () => deleteProfileUseCase.execute(reauthenticateWith: any(named: 'reauthenticateWith')),
    ).thenAnswer((_) async => result);

    blocTest<DeleteProfileCubit, DeleteProfileState>(
      'passes the provider to the use case and emits completed',
      build: buildCubit,
      setUp: () => stubResult(DeleteProfileResult.completed),
      act: (cubit) => cubit.reauthenticateAndDelete(ReauthProvider.google),
      expect: () => [const DeleteProfileState.loading(), const DeleteProfileState.completed()],
      verify: (_) => verify(() => deleteProfileUseCase.execute(reauthenticateWith: ReauthProvider.google)).called(1),
    );

    blocTest<DeleteProfileCubit, DeleteProfileState>(
      'returns to the reauth prompt with a mismatch flag when another account was used',
      build: buildCubit,
      setUp: () => stubResult(DeleteProfileResult.accountMismatch),
      act: (cubit) => cubit.reauthenticateAndDelete(ReauthProvider.google),
      expect: () => [const DeleteProfileState.loading(), const DeleteProfileState.authRequired(accountMismatch: true)],
    );

    blocTest<DeleteProfileCubit, DeleteProfileState>(
      'returns to the reauth prompt when the user cancels',
      build: buildCubit,
      setUp: () => stubResult(DeleteProfileResult.reauthenticationCancelled),
      act: (cubit) => cubit.reauthenticateAndDelete(ReauthProvider.apple),
      expect: () => [const DeleteProfileState.loading(), const DeleteProfileState.authRequired()],
    );

    blocTest<DeleteProfileCubit, DeleteProfileState>(
      'emits error when nobody is signed in',
      build: buildCubit,
      setUp: () => stubResult(DeleteProfileResult.notSignedIn),
      act: (cubit) => cubit.reauthenticateAndDelete(ReauthProvider.google),
      expect: () => [const DeleteProfileState.loading(), const DeleteProfileState.error()],
    );

    test('does not emit after being closed while deletion runs', () async {
      final result = Completer<DeleteProfileResult>();
      when(
        () => deleteProfileUseCase.execute(reauthenticateWith: any(named: 'reauthenticateWith')),
      ).thenAnswer((_) => result.future);
      final cubit = buildCubit();

      final deletion = cubit.reauthenticateAndDelete(ReauthProvider.google);
      await cubit.close();
      result.complete(DeleteProfileResult.completed);

      await expectLater(deletion, completes);
      verifyNever(
        () => crashlyticsService.recordError(
          exception: any(named: 'exception'),
          stackTrace: any(named: 'stackTrace'),
          reason: any(named: 'reason'),
        ),
      );
    });
  });
}
