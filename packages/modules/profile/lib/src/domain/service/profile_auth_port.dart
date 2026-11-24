/// Sign-in providers the user can confirm their identity with.
enum ReauthProvider { google, apple }

/// The user cancelled the reauthentication prompt.
class ReauthenticationCancelled implements Exception {
  const new();
}

/// The user confirmed with a different account than the signed-in one.
class ReauthenticationAccountMismatch implements Exception {
  const new();
}

/// Auth operations the profile domain needs from the auth module.
abstract interface class ProfileAuthPort {

  /// Returns the signed-in user's id, or null when not authenticated.
  Future<String?> getAuthenticatedUserId();

  /// Confirms the signed-in user's identity without changing who is signed in.
  ///
  /// Throws [ReauthenticationCancelled] or [ReauthenticationAccountMismatch].
  Future<void> reauthenticate(ReauthProvider provider);

  /// Deletes the signed-in user's account.
  Future<void> deleteUser();

}
