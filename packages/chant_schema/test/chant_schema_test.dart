import 'package:flutter_test/flutter_test.dart';

import 'package:chant_schema/chant_schema.dart';

void main() {
  final chant = ChantEntity(
    id: 'heart-sutra',
    name: 'Heart Sutra',
    blurHash: 'LEHV6nWB2yk8',
    order: 2,
    length: const Duration(minutes: 3, seconds: 5),
    metaData: ChantMetaDataEntity(
      id: 'heart-sutra',
      audioVersion: 1,
      lyricsVersion: 2,
      coverVersion: 3,
      audioSha256: 'a',
      lyricsSha256: 'l',
      coverSha256: 'c',
      audioBytes: 10,
      lyricsBytes: 20,
      coverBytes: 30,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    ),
  );

  test('serializes to the document shape with a nested metaData map', () {
    expect(chant.toJson(), {
      'id': 'heart-sutra',
      'name': 'Heart Sutra',
      'blurHash': 'LEHV6nWB2yk8',
      'order': 2,
      'length': 185,
      'metaData': {
        'id': 'heart-sutra',
        'audioVersion': 1,
        'lyricsVersion': 2,
        'coverVersion': 3,
        'audioSha256': 'a',
        'lyricsSha256': 'l',
        'coverSha256': 'c',
        'audioBytes': 10,
        'lyricsBytes': 20,
        'coverBytes': 30,
        'updatedAt': 1700000000000,
      },
    });
  });

  test('round-trips through JSON', () {
    expect(ChantEntity.fromJson(chant.toJson()), chant);
  });

  test('rejects a document without a blurHash', () {
    final json = chant.toJson()..remove('blurHash');
    expect(() => ChantEntity.fromJson(json), throwsA(isA<TypeError>()));
  });

  test('asset field names match the serialized metaData keys', () {
    final metaData = chant.metaData.toJson();
    for (final type in ChantAssetType.values) {
      expect(metaData[type.versionField], chant.metaData.getVersion(type));
      expect(metaData[type.sha256Field], chant.metaData.getHash(type));
      expect(metaData[type.bytesField], chant.metaData.getBytes(type));
    }
  });

  test('asset storage paths follow the catalog layout', () {
    expect(chant.metaData.getStoragePath(.audio), '/chants/heart-sutra/chant.mp3');
    expect(ChantAssetType.lyrics.storagePath('x'), '/chants/x/chant.ass');
    expect(ChantAssetType.cover.storagePath('x'), '/chants/x/cover.jpg');
  });
}
