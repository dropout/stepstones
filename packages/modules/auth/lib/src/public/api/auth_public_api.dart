import 'package:auth/src/public/types/auth_public_failure.dart';

typedef AuthSigninResult = ({String userId, bool isFirstSignin});
typedef AuthSession = ({bool isAuthenticated, String? userId});

abstract interface class AuthPublicApi {

  Stream<AuthSession> get authSessionStream;

  Future<AuthSigninResult> signInWithApple();
  Future<AuthSigninResult> signInWithGoogle();

  /// Confirms the signed-in user's identity before a sensitive operation, without changing auth state.
  ///
  /// Throws [AuthPublicReauthenticationUserMismatch] when a different account is chosen.
  Future<void> reauthenticateWithApple();
  Future<void> reauthenticateWithGoogle();

  Future<String> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
  Future<void> deleteUser();

}
