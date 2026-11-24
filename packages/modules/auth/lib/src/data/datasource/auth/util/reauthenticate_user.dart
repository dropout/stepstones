import 'package:firebase_provider/firebase_provider.dart' as firebase_auth;

import 'package:auth/src/data/datasource/auth/exception.dart';

/// Reauthenticates [user] with [credential]; Firebase rejects a credential of another account.
/// Used by implementations of [AuthProviderTemplate] to reauthenticate the current user.
Future<void> reauthenticateUser(firebase_auth.User user, firebase_auth.AuthCredential credential) async {
  try {
    await user.reauthenticateWithCredential(credential);
  } on firebase_auth.FirebaseAuthException catch (e) {
    if (e.code == 'user-mismatch') {
      throw const ReauthenticationUserMismatch('Reauthenticated with a different account');
    }
    rethrow;
  }
}
