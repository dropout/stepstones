import 'package:admin_access/src/domain/entity/admin_access_entity.dart';

abstract interface class AdminAccessRepository {
  /// Emits the current access and every later change of the signed-in user or their token.
  Stream<AdminAccessEntity> watchAccess();

  /// Re-reads the claims from the server, picking up a grant made after sign-in.
  Future<AdminAccessEntity> refreshAccess();
}
