import 'package:auth/auth.dart';
import 'package:profile/src/domain/service/profile_auth_port.dart';

class DefaultProfileAuthPort implements ProfileAuthPort {
  final AuthPublicApi authApi;

  const DefaultProfileAuthPort({required this.authApi});

  @override
  Future<String?> getAuthenticatedUserId() async {
    final session = await authApi.authSessionStream.first;
    return session.isAuthenticated ? session.userId : null;
  }

  @override
  Future<void> reauthenticate(ReauthProvider provider) async {
    try {
      switch (provider) {
        case ReauthProvider.google:
          await authApi.reauthenticateWithGoogle();
        case ReauthProvider.apple:
          await authApi.reauthenticateWithApple();
      }
    } on AuthPublicSignInCancelled {
      throw const ReauthenticationCancelled();
    } on AuthPublicReauthenticationUserMismatch {
      throw const ReauthenticationAccountMismatch();
    }
  }

  @override
  Future<void> deleteUser() => authApi.deleteUser();
}
