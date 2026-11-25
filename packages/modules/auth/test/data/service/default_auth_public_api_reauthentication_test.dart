import 'package:auth/auth.dart';
import 'package:auth/src/data/datasource/auth/exception.dart';
import 'package:auth/src/data/service/default_auth_public_api.dart';
import 'package:auth/src/domain/enum/signin_auth_provider_type.dart';
import 'package:auth/src/domain/repository/auth_repository.dart';
import 'package:auth/src/domain/usecase/sign_in_with_auth_provider_use_case.dart';
import 'package:auth/src/domain/usecase/sign_in_with_email_and_password_use_case.dart';
import 'package:auth/src/domain/usecase/sign_out_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSigninUseCase extends Mock implements SigninWithAuthProviderUseCase {}

class _MockEmailSigninUseCase extends Mock implements SignInWithEmailAndPasswordUseCase {}

class _MockSignoutUseCase extends Mock implements SignoutUseCase {}

void main() {
  late _MockAuthRepository repository;
  late _MockSigninUseCase signinUseCase;
  late DefaultAuthPublicApi api;

  setUpAll(() => registerFallbackValue(SigninAuthProviderType.google));

  setUp(() {
    repository = _MockAuthRepository();
    signinUseCase = _MockSigninUseCase();
    api = DefaultAuthPublicApi(
      authRepository: repository,
      signInWithAuthProviderUseCase: signinUseCase,
      signInWithEmailAndPasswordUseCase: _MockEmailSigninUseCase(),
      signOutUseCase: _MockSignoutUseCase(),
    );
  });

  test('reauthenticateWithGoogle reauthenticates without signing in', () async {
    when(() => repository.reauthenticateWithAuthProvider(any())).thenAnswer((_) async {});

    await api.reauthenticateWithGoogle();

    verify(() => repository.reauthenticateWithAuthProvider(SigninAuthProviderType.google)).called(1);
    verifyZeroInteractions(signinUseCase);
  });

  test('reauthenticateWithApple reauthenticates with Apple', () async {
    when(() => repository.reauthenticateWithAuthProvider(any())).thenAnswer((_) async {});

    await api.reauthenticateWithApple();

    verify(() => repository.reauthenticateWithAuthProvider(SigninAuthProviderType.apple)).called(1);
  });

  test('maps an account mismatch to AuthPublicReauthenticationUserMismatch', () {
    when(() => repository.reauthenticateWithAuthProvider(any()))
        .thenThrow(const ReauthenticationUserMismatch('different account'));

    expect(api.reauthenticateWithGoogle, throwsA(isA<AuthPublicReauthenticationUserMismatch>()));
  });

  test('maps a cancelled prompt to AuthPublicSignInCancelled', () {
    when(() => repository.reauthenticateWithAuthProvider(any())).thenThrow(const SignInCancelled('cancelled'));

    expect(api.reauthenticateWithGoogle, throwsA(isA<AuthPublicSignInCancelled>()));
  });

  test('maps other errors to AuthPublicUnknownFailure and keeps the cause', () async {
    final cause = Exception('network');
    when(() => repository.reauthenticateWithAuthProvider(any())).thenThrow(cause);

    await expectLater(
      api.reauthenticateWithApple,
      throwsA(isA<AuthPublicUnknownFailure>().having((f) => f.cause, 'cause', same(cause))),
    );
  });

  test('maps deleteUser errors to public failures', () {
    when(() => repository.deleteUser()).thenThrow(Exception('requires-recent-login'));

    expect(api.deleteUser, throwsA(isA<AuthPublicUnknownFailure>()));
  });

  test('maps auth session stream errors to public failures', () {
    when(() => repository.authStateChange).thenAnswer((_) => Stream.error(const SignInCancelled('cancelled')));

    expect(api.authSessionStream, emitsError(isA<AuthPublicSignInCancelled>()));
  });
}
