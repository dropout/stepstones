import 'package:firebase_provider/firebase_provider.dart';

import 'package:admin_access/src/domain/entity/admin_access_entity.dart';
import 'package:admin_access/src/domain/repository/admin_access_repository.dart';

class FirebaseAdminAccessRepository implements AdminAccessRepository {
  // Must match the claim set by set_admin_claim.mjs and checked in the security rules.
  static const adminClaim = 'admin';

  final FirebaseAuth firebaseAuth;

  const FirebaseAdminAccessRepository(this.firebaseAuth);

  @override
  Stream<AdminAccessEntity> watchAccess() =>
      firebaseAuth.idTokenChanges().asyncMap((user) => _resolve(user, forceRefresh: false));

  @override
  Future<AdminAccessEntity> refreshAccess() => _resolve(firebaseAuth.currentUser, forceRefresh: true);

  Future<AdminAccessEntity> _resolve(User? user, {required bool forceRefresh}) async {
    if (user == null) {
      return const AdminAccessEntity(status: .signedOut);
    }
    final token = await user.getIdTokenResult(forceRefresh);
    final isAdmin = token.claims?[adminClaim] == true;
    return AdminAccessEntity(status: isAdmin ? .authorized : .unauthorized, userId: user.uid, email: user.email);
  }
}
