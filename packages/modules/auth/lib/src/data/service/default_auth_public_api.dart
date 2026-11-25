import 'dart:async';

import 'package:auth/src/data/mapper/auth_public_failure_mapper.dart';
import 'package:auth/src/domain/repository/auth_repository.dart';
import 'package:auth/src/domain/usecase/sign_in_with_auth_provider_use_case.dart';
import 'package:auth/src/domain/usecase/sign_in_with_email_and_password_use_case.dart';
import 'package:auth/src/domain/usecase/sign_out_use_case.dart';
import 'package:auth/src/public/api/auth_public_api.dart';

/// Default [AuthPublicApi]; every error leaves the module as an [AuthPublicFailure].
class DefaultAuthPublicApi implements AuthPublicApi {
  final AuthRepository authRepository;

  final SigninWithAuthProviderUseCase signInWithAuthProviderUseCase;
  final SignInWithEmailAndPasswordUseCase signInWithEmailAndPasswordUseCase;
  final SignoutUseCase signOutUseCase;

  const DefaultAuthPublicApi({
    required this.authRepository,
    required this.signInWithAuthProviderUseCase,
    required this.signInWithEmailAndPasswordUseCase,
    required this.signOutUseCase,
  });

  @override
  Stream<AuthSession> get authSessionStream {
    return authRepository.authStateChange
        .map<AuthSession>((user) {
          if (user == null) {
            return (isAuthenticated: false, userId: null);
          }
          return (isAuthenticated: true, userId: user.uid);
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) => sink.addError(error.toPublicFailure(), stackTrace),
          ),
        );
  }

  @override
  Future<AuthSigninResult> signInWithApple() => _guard(() async {
    final result = await signInWithAuthProviderUseCase.execute(.apple);
    return (userId: result.user.uid, isFirstSignin: result.isFirstSignin);
  });

  @override
  Future<AuthSigninResult> signInWithGoogle() => _guard(() async {
    final result = await signInWithAuthProviderUseCase.execute(.google);
    return (userId: result.user.uid, isFirstSignin: result.isFirstSignin);
  });

  @override
  Future<void> reauthenticateWithApple() => _guard(() => authRepository.reauthenticateWithAuthProvider(.apple));

  @override
  Future<void> reauthenticateWithGoogle() => _guard(() => authRepository.reauthenticateWithAuthProvider(.google));

  @override
  Future<String> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) => _guard(() async {
    final user = await authRepository.signupWithEmailAndPassword(email: email, password: password);
    return user.uid;
  });

  @override
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => _guard(() => signInWithEmailAndPasswordUseCase.execute(email: email, password: password));

  @override
  Future<void> signOut() => _guard(authRepository.signOut);

  @override
  Future<void> deleteUser() => _guard(authRepository.deleteUser);

  /// Keeps the original stack trace so crash reports point at the real failure site.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error.toPublicFailure(), stackTrace);
    }
  }
}
