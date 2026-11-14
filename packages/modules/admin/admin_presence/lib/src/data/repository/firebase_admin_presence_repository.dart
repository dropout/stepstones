import 'package:firebase_provider/firebase_provider.dart';

import 'package:admin_presence/src/data/mapper/admin_presence_mapper.dart';
import 'package:admin_presence/src/domain/entity/admin_presence_entity.dart';
import 'package:admin_presence/src/domain/repository/admin_presence_repository.dart';

class FirebaseAdminPresenceRepository implements AdminPresenceRepository {
  final FirebaseFirestore firestore;

  const FirebaseAdminPresenceRepository({required this.firestore});

  @override
  Stream<List<AdminPresenceEntity>> watchPresence({required DateTime since, required int limit}) {
    return firestore
        .collection('presence')
        .where('startedAt', isGreaterThanOrEqualTo: since.millisecondsSinceEpoch)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => [for (final doc in snapshot.docs) adminPresenceFromFirestore(doc.id, doc.data())]);
  }
}
