import 'package:chant_schema/chant_schema.dart';
import 'package:clock/clock.dart';
import 'package:firebase_provider/firebase_provider.dart';

import 'package:admin_chants/src/data/mapper/admin_chant_mapper.dart';
import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/entity/prepared_chant_asset_entity.dart';
import 'package:admin_chants/src/domain/failure/chant_failure.dart';
import 'package:admin_chants/src/domain/repository/admin_chant_repository.dart';

class FirebaseAdminChantRepository implements AdminChantRepository {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  const FirebaseAdminChantRepository({required this.firestore, required this.storage});

  CollectionReference<Map<String, dynamic>> get _chants => firestore.collection(chantsCollection);

  @override
  Stream<List<AdminChantEntity>> watchChants() {
    // Sorted client-side because orderBy would hide documents that lack the order field.
    return _chants.snapshots().map((snapshot) {
      final chants = snapshot.docs.map((doc) => adminChantFromFirestore(doc.id, doc.data())).toList();
      chants.sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
      return chants;
    });
  }

  // Single-field updates keep the server-maintained playCount untouched, as the security rules require.
  @override
  Future<void> renameChant({required String chantId, required String name}) =>
      _chants.doc(chantId).update({'name': name});

  @override
  Future<void> reorderChants(List<String> orderedChantIds) {
    final batch = firestore.batch();
    for (final (index, chantId) in orderedChantIds.indexed) {
      batch.update(_chants.doc(chantId), {'order': index});
    }
    return batch.commit();
  }

  @override
  Future<void> createChant({
    required String chantId,
    required String name,
    required int order,
    required PreparedChantAssetEntity audio,
    required PreparedChantAssetEntity lyrics,
    required PreparedChantAssetEntity cover,
  }) async {
    final document = _chants.doc(chantId);
    // Checked before uploading so an existing chant's files are never overwritten by a name clash.
    if ((await document.get()).exists) throw const ChantFailure(.duplicateId);

    for (final asset in [audio, lyrics, cover]) {
      await _upload(chantId, asset);
    }

    final payload = adminChantToFirestore(
      chantId: chantId,
      name: name,
      order: order,
      audio: audio,
      lyrics: lyrics,
      cover: cover,
      updatedAt: clock.now(),
    );
    // The document is written last, so clients only ever see a chant whose files exist.
    await firestore.runTransaction((transaction) async {
      if ((await transaction.get(document)).exists) throw const ChantFailure(.duplicateId);
      transaction.set(document, payload);
    });
  }

  @override
  Future<void> replaceChantAsset({required String chantId, required PreparedChantAssetEntity asset}) async {
    await _upload(chantId, asset);
    await _chants
        .doc(chantId)
        .update(adminChantAssetUpdateToFirestore(chantId: chantId, asset: asset, updatedAt: clock.now()));
  }

  Future<void> _upload(String chantId, PreparedChantAssetEntity asset) async {
    await storage
        .ref(asset.type.storagePath(chantId))
        .putData(asset.bytes, SettableMetadata(contentType: asset.type.contentType));
  }
}
