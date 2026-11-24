import 'package:firebase_provider/firebase_provider.dart' as firebase_auth;

import 'package:auth/src/data/datasource/auth/model/signin_result.dart';
import 'package:auth/src/data/datasource/auth/enum/auth_provider_type.dart';

import 'apple_auth_template.dart';
import 'google_auth_template.dart';

/// Template interface for authentication providers.
abstract class AuthProviderTemplate {

  factory AuthProviderTemplate(
    firebase_auth.FirebaseAuth firebaseAuth,
    AuthProviderType authProviderType) {
    switch (authProviderType) {
      case .google:
        return GoogleAuthTemplate(firebaseAuth);
      case .apple:
        return AppleAuthTemplate(firebaseAuth);
    }
  }

  /// Signs in the user with the specified authentication provider. 
  /// Returns a [SigninResult] containing the signed-in user's information 
  /// and whether it is the user's first sign-in.
  Future<SigninResult> signIn();

  /// Confirms the signed-in user's identity without switching accounts.
  Future<void> reauthenticate();

}
