import 'package:chant_schema/chant_schema.dart';
import 'package:firebase_provider/firebase_provider.dart';

import 'package:admin_chants/src/domain/entity/admin_chant_asset_entity.dart';
import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/entity/prepared_chant_asset_entity.dart';

/// Maps a `chants/{id}` document; tolerant of missing fields so a malformed chant stays visible and fixable.
AdminChantEntity adminChantFromFirestore(String documentId, Map<String, dynamic> data) {
  final metaData = data['metaData'];
  final meta = metaData is Map ? metaData : const <String, dynamic>{};
  final updatedAt = _int(meta['updatedAt']);

  AdminChantAssetEntity asset(ChantAssetType type) => AdminChantAssetEntity(
    version: _int(meta[type.versionField]),
    sha256: _string(meta[type.sha256Field]) ?? '',
    bytes: _int(meta[type.bytesField]),
  );

  return AdminChantEntity(
    id: documentId,
    name: _string(data['name']) ?? '',
    order: _int(data['order']),
    length: Duration(seconds: _int(data['length'])),
    playCount: _int(data['playCount']),
    blurHash: _string(data['blurHash']),
    audio: asset(.audio),
    lyrics: asset(.lyrics),
    cover: asset(.cover),
    assetsUpdatedAt: updatedAt > 0 ? DateTime.fromMillisecondsSinceEpoch(updatedAt) : null,
    isLoadableByMobileApp: _parsesAsMobileChant(data),
  );
}

/// Runs the mobile app's own parser, so the warning matches exactly what the app can load.
bool _parsesAsMobileChant(Map<String, dynamic> data) {
  try {
    return ChantEntity.fromJson(data).blurHash.isNotEmpty;
  } catch (_) {
    return false;
  }
}

int _int(Object? value) => value is num ? value.toInt() : 0;

String? _string(Object? value) => value is String ? value : null;

/// Builds a new `chants/{id}` document from the shared schema the mobile app parses.
Map<String, Object?> adminChantToFirestore({
  required String chantId,
  required String name,
  required int order,
  required PreparedChantAssetEntity audio,
  required PreparedChantAssetEntity lyrics,
  required PreparedChantAssetEntity cover,
  required DateTime updatedAt,
}) => ChantEntity(
  id: chantId,
  name: name,
  order: order,
  length: audio.length!,
  blurHash: cover.blurHash!,
  metaData: ChantMetaDataEntity(
    id: chantId,
    audioVersion: 1,
    lyricsVersion: 1,
    coverVersion: 1,
    audioSha256: audio.sha256,
    lyricsSha256: lyrics.sha256,
    coverSha256: cover.sha256,
    audioBytes: audio.bytes.length,
    lyricsBytes: lyrics.bytes.length,
    coverBytes: cover.bytes.length,
    updatedAt: updatedAt,
  ),
).toJson();

/// Builds the field updates for a replaced asset; the version increment invalidates mobile caches.
Map<String, Object?> adminChantAssetUpdateToFirestore({
  required String chantId,
  required PreparedChantAssetEntity asset,
  required DateTime updatedAt,
}) => {
  // Repairs legacy documents that lack the nested id the mobile model requires.
  'metaData.id': chantId,
  'metaData.${asset.type.versionField}': FieldValue.increment(1),
  'metaData.${asset.type.sha256Field}': asset.sha256,
  'metaData.${asset.type.bytesField}': asset.bytes.length,
  'metaData.updatedAt': updatedAt.millisecondsSinceEpoch,
  if (asset.type == ChantAssetType.audio) 'length': asset.length!.inSeconds,
  if (asset.type == ChantAssetType.cover) 'blurHash': asset.blurHash,
};
