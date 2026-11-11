/// Auth operations the profile domain needs from the auth module.
abstract interface class ProfileAuthPort {

  /// Returns the signed-in user's id, or null when not authenticated.
  Future<String?> getAuthenticatedUserId();

  /// Deletes the signed-in user's account.
  Future<void> deleteUser();

}
