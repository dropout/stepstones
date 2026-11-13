import 'package:firebase_provider/firebase_provider.dart';

import 'package:admin_chants/src/domain/entity/admin_chant_asset_entity.dart';
import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/entity/prepared_chant_asset_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';

/// Maps a `chants/{id}` document; tolerant of missing fields so a malformed chant stays visible and fixable.
AdminChantEntity adminChantFromFirestore(String documentId, Map<String, dynamic> data) {
  final metaData = data['metaData'];
  final meta = metaData is Map ? metaData : const <String, dynamic>{};
  final updatedAt = _int(meta['updatedAt']);

  AdminChantAssetEntity asset(String prefix) => AdminChantAssetEntity(
    version: _int(meta['${prefix}Version']),
    sha256: _string(meta['${prefix}Sha256']) ?? '',
    bytes: _int(meta['${prefix}Bytes']),
  );

  return AdminChantEntity(
    id: documentId,
    name: _string(data['name']) ?? '',
    order: _int(data['order']),
    length: Duration(seconds: _int(data['length'])),
    playCount: _int(data['playCount']),
    blurHash: _string(data['blurHash']),
    audio: asset('audio'),
    lyrics: asset('lyrics'),
    cover: asset('cover'),
    assetsUpdatedAt: updatedAt > 0 ? DateTime.fromMillisecondsSinceEpoch(updatedAt) : null,
  );
}

int _int(Object? value) => value is num ? value.toInt() : 0;

String? _string(Object? value) => value is String ? value : null;

Map<String, Object?> _assetFields(PreparedChantAssetEntity asset, {required Object version}) => {
  '${asset.type.name}Version': version,
  '${asset.type.name}Sha256': asset.sha256,
  '${asset.type.name}Bytes': asset.bytes.length,
};

/// Builds a new `chants/{id}` document in the shape the mobile app's ChantEntity parses.
Map<String, Object?> adminChantToFirestore({
  required String chantId,
  required String name,
  required int order,
  required PreparedChantAssetEntity audio,
  required PreparedChantAssetEntity lyrics,
  required PreparedChantAssetEntity cover,
  required DateTime updatedAt,
}) => {
  'id': chantId,
  'name': name,
  'order': order,
  'length': audio.length!.inSeconds,
  'blurHash': cover.blurHash,
  'metaData': {
    'id': chantId,
    for (final asset in [audio, lyrics, cover]) ..._assetFields(asset, version: 1),
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  },
};

/// Builds the field updates for a replaced asset; the version increment invalidates mobile caches.
Map<String, Object?> adminChantAssetUpdateToFirestore({
  required String chantId,
  required PreparedChantAssetEntity asset,
  required DateTime updatedAt,
}) => {
  // Repairs legacy documents that lack the nested id the mobile model requires.
  'metaData.id': chantId,
  for (final MapEntry(:key, :value) in _assetFields(asset, version: FieldValue.increment(1)).entries)
    'metaData.$key': value,
  'metaData.updatedAt': updatedAt.millisecondsSinceEpoch,
  if (asset.type == ChantAssetType.audio) 'length': asset.length!.inSeconds,
  if (asset.type == ChantAssetType.cover) 'blurHash': asset.blurHash,
};
