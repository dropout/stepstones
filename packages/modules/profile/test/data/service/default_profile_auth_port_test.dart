import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:profile/src/data/service/default_profile_auth_port.dart';
import 'package:profile/src/domain/service/profile_auth_port.dart';

import '../../profile_mock_definitions.dart';

void main() {
  late MockAuthPublicApi authApi;
  late DefaultProfileAuthPort port;

  setUp(() {
    authApi = MockAuthPublicApi();
    port = DefaultProfileAuthPort(authApi: authApi);
  });

  group('reauthenticate', () {
    test('reauthenticates with Google without signing in', () async {
      when(() => authApi.reauthenticateWithGoogle()).thenAnswer((_) async {});

      await port.reauthenticate(ReauthProvider.google);

      verify(() => authApi.reauthenticateWithGoogle()).called(1);
      verifyNever(() => authApi.signInWithGoogle());
    });

    test('reauthenticates with Apple', () async {
      when(() => authApi.reauthenticateWithApple()).thenAnswer((_) async {});

      await port.reauthenticate(ReauthProvider.apple);

      verify(() => authApi.reauthenticateWithApple()).called(1);
    });

    test('maps a cancelled prompt to ReauthenticationCancelled', () {
      when(() => authApi.reauthenticateWithGoogle()).thenThrow(const AuthPublicSignInCancelled('cancelled'));

      expect(() => port.reauthenticate(ReauthProvider.google), throwsA(isA<ReauthenticationCancelled>()));
    });

    test('maps a different account to ReauthenticationAccountMismatch', () {
      when(() => authApi.reauthenticateWithGoogle())
          .thenThrow(const AuthPublicReauthenticationUserMismatch('different account'));

      expect(() => port.reauthenticate(ReauthProvider.google), throwsA(isA<ReauthenticationAccountMismatch>()));
    });

    test('rethrows other failures', () {
      when(() => authApi.reauthenticateWithGoogle()).thenThrow(const AuthPublicUnknownFailure('network'));

      expect(() => port.reauthenticate(ReauthProvider.google), throwsA(isA<AuthPublicUnknownFailure>()));
    });
  });
}
