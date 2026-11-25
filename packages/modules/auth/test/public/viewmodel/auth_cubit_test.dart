import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthPublicApi extends Mock implements AuthPublicApi {}

class _MockProfileNavigator extends Mock implements ProfileNavigator {}

void main() {
  late _MockAuthPublicApi authApi;
  late MockCrashlyticsService crashlytics;
  late AuthCubit cubit;

  setUp(() {
    authApi = _MockAuthPublicApi();
    crashlytics = MockCrashlyticsService();
    when(() => authApi.authSessionStream).thenAnswer((_) => const Stream.empty());
    cubit = AuthCubit(
      profileNavigator: _MockProfileNavigator(),
      authApi: authApi,
      analyticsService: MockAnalyticsService(),
      crashlyticsService: crashlytics,
    );
  });

  tearDown(() => cubit.close());

  group('cancelled sign-in', () {
    final cases = <String, Future<void> Function()>{
      'Google': () => cubit.signinWithGoogle(),
      'Apple': () => cubit.signinWithApple(),
    };

    for (final MapEntry(key: provider, value: signIn) in cases.entries) {
      test('$provider returns to signed out without reporting an error', () async {
        when(() => authApi.signInWithGoogle()).thenThrow(const AuthPublicSignInCancelled('cancelled'));
        when(() => authApi.signInWithApple()).thenThrow(const AuthPublicSignInCancelled('cancelled'));

        await signIn();

        expect(cubit.state, const AuthState.signedOut());
        verifyNever(
          () => crashlytics.recordError(
            exception: any(named: 'exception'),
            stackTrace: any(named: 'stackTrace'),
            reason: any(named: 'reason'),
          ),
        );
      });
    }
  });

  test('other sign-in failures are reported and emit an error state', () async {
    when(() => authApi.signInWithGoogle()).thenThrow(const AuthPublicUnknownFailure('network'));

    await cubit.signinWithGoogle();

    expect(cubit.state, const AuthState.error());
    verify(
      () => crashlytics.recordError(
        exception: any(named: 'exception'),
        stackTrace: any(named: 'stackTrace'),
        reason: any(named: 'reason'),
      ),
    ).called(1);
  });
}
