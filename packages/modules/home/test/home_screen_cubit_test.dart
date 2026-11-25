import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:auth/auth.dart';
import 'package:core/core.dart';

import 'package:home/src/public/enum/home_screen_view_state.dart';
import 'package:home/src/public/viewmodel/home_screen_cubit.dart';

import 'home_mock_definitions.dart';

void main() {
  late MockAuthPublicApi authPublicApi;
  late MockCrashlyticsService crashlyticsService;
  late StreamController<AuthSession> authSessions;

  const AuthSession signedIn = (isAuthenticated: true, userId: 'userid');
  const AuthSession signedOut = (isAuthenticated: false, userId: null);

  setUpAll(() {
    final storage = MockHydratedStorage();
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.read(any())).thenReturn(null);
    HydratedBloc.storage = storage;
  });

  setUp(() {
    authPublicApi = MockAuthPublicApi();
    crashlyticsService = MockCrashlyticsService();
    authSessions = StreamController<AuthSession>();
    when(() => authPublicApi.authSessionStream).thenAnswer((_) => authSessions.stream);
  });

  // Not awaited: close() never completes on a controller that was never listened to.
  tearDown(() {
    authSessions.close();
  });

  HomeScreenCubit buildCubit({HomeScreenViewState? preferred}) => HomeScreenCubit(
    initialState: preferred == null ? null : HomeScreenState(preferredSessionType: preferred),
    authPublicApi: authPublicApi,
    crashlyticsService: crashlyticsService,
  );

  group('HomeScreenState.sessionType', () {
    test('uses the preference while auth is unknown', () {
      expect(const HomeScreenState(preferredSessionType: .chanting).sessionType, HomeScreenViewState.chanting);
    });

    test('uses the preference when signed in', () {
      expect(
        const HomeScreenState(preferredSessionType: .chanting, isSignedIn: true).sessionType,
        HomeScreenViewState.chanting,
      );
    });

    test('forces sitting when signed out', () {
      expect(
        const HomeScreenState(preferredSessionType: .chanting, isSignedIn: false).sessionType,
        HomeScreenViewState.sitting,
      );
    });
  });

  group('HomeScreenCubit', () {
    blocTest<HomeScreenCubit, HomeScreenState>(
      'tracks auth session changes',
      build: buildCubit,
      act: (_) async {
        authSessions.add(signedIn);
        await Future<void>.delayed(Duration.zero);
        authSessions.add(signedOut);
      },
      expect: () => const [HomeScreenState(isSignedIn: true), HomeScreenState(isSignedIn: false)],
    );

    blocTest<HomeScreenCubit, HomeScreenState>(
      'keeps the chanting preference across sign-out and sign-in',
      build: () => buildCubit(preferred: .chanting),
      act: (_) async {
        authSessions.add(signedOut);
        await Future<void>.delayed(Duration.zero);
        authSessions.add(signedIn);
      },
      verify: (cubit) {
        expect(cubit.state.preferredSessionType, HomeScreenViewState.chanting);
        expect(cubit.state.sessionType, HomeScreenViewState.chanting);
      },
    );

    blocTest<HomeScreenCubit, HomeScreenState>(
      'setSessionType updates only the preference',
      build: buildCubit,
      seed: () => const HomeScreenState(isSignedIn: true),
      act: (cubit) => cubit.setSessionType(.chanting),
      expect: () => const [HomeScreenState(preferredSessionType: .chanting, isSignedIn: true)],
    );

    test('persists only the preference', () {
      final cubit = buildCubit();
      expect(cubit.toJson(const HomeScreenState(preferredSessionType: .chanting, isSignedIn: false)), {
        'sessionType': 'chanting',
      });
      expect(cubit.fromJson({'sessionType': 'chanting'}), const HomeScreenState(preferredSessionType: .chanting));
      cubit.close();
    });

    test('cancels the auth subscription on close', () async {
      final cubit = buildCubit();
      expect(authSessions.hasListener, isTrue);
      await cubit.close();
      expect(authSessions.hasListener, isFalse);
    });
  });
}
