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
  Future<void> deleteUser() => authApi.deleteUser();
}
