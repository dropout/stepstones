import 'dart:typed_data';

import 'package:firebase_provider/firebase_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_chants/src/data/mapper/admin_chant_mapper.dart';
import 'package:admin_chants/src/domain/entity/admin_chant_asset_entity.dart';
import 'package:admin_chants/src/domain/entity/prepared_chant_asset_entity.dart';

void main() {
  test('maps a complete chant document', () {
    final chant = adminChantFromFirestore('heart-sutra', {
      'id': 'heart-sutra',
      'name': 'Heart Sutra',
      'order': 2,
      'length': 185,
      'playCount': 7,
      'blurHash': 'LEHV6nWB2yk8',
      'metaData': {
        'audioVersion': 3,
        'audioSha256': 'aaa',
        'audioBytes': 2048,
        'lyricsVersion': 1,
        'lyricsSha256': 'bbb',
        'lyricsBytes': 512,
        'coverVersion': 2,
        'coverSha256': 'ccc',
        'coverBytes': 1024,
        'updatedAt': 1700000000000,
      },
    });

    expect(chant.id, 'heart-sutra');
    expect(chant.name, 'Heart Sutra');
    expect(chant.order, 2);
    expect(chant.length, const Duration(minutes: 3, seconds: 5));
    expect(chant.playCount, 7);
    expect(chant.isLoadableByMobileApp, isTrue);
    expect(chant.audio, const AdminChantAssetEntity(version: 3, sha256: 'aaa', bytes: 2048));
    expect(chant.lyrics, const AdminChantAssetEntity(version: 1, sha256: 'bbb', bytes: 512));
    expect(chant.cover, const AdminChantAssetEntity(version: 2, sha256: 'ccc', bytes: 1024));
    expect(chant.assetsUpdatedAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
  });

  test('keeps a malformed document visible with safe defaults', () {
    final chant = adminChantFromFirestore('broken', {'name': 42, 'length': 'long', 'metaData': 'nope'});

    expect(chant.id, 'broken');
    expect(chant.name, '');
    expect(chant.order, 0);
    expect(chant.length, Duration.zero);
    expect(chant.playCount, 0);
    expect(chant.isLoadableByMobileApp, isFalse);
    expect(chant.audio, const AdminChantAssetEntity());
    expect(chant.assetsUpdatedAt, isNull);
  });

  test('uses the document id, not the id field', () {
    expect(adminChantFromFirestore('doc-id', {'id': 'other'}).id, 'doc-id');
  });

  group('writing', () {
    final audio = PreparedChantAssetEntity(
      type: .audio,
      bytes: Uint8List(2048),
      sha256: 'aaa',
      length: const Duration(seconds: 185),
    );
    final lyrics = PreparedChantAssetEntity(type: .lyrics, bytes: Uint8List(512), sha256: 'bbb');
    final cover = PreparedChantAssetEntity(type: .cover, bytes: Uint8List(1024), sha256: 'ccc', blurHash: 'LEHV6n');
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    test('builds a new chant document the mobile model can parse', () {
      final document = adminChantToFirestore(
        chantId: 'heart-sutra',
        name: 'Heart Sutra',
        order: 3,
        audio: audio,
        lyrics: lyrics,
        cover: cover,
        updatedAt: updatedAt,
      );

      expect(document, {
        'id': 'heart-sutra',
        'name': 'Heart Sutra',
        'order': 3,
        'length': 185,
        'blurHash': 'LEHV6n',
        'metaData': {
          'id': 'heart-sutra',
          'audioVersion': 1,
          'audioSha256': 'aaa',
          'audioBytes': 2048,
          'lyricsVersion': 1,
          'lyricsSha256': 'bbb',
          'lyricsBytes': 512,
          'coverVersion': 1,
          'coverSha256': 'ccc',
          'coverBytes': 1024,
          'updatedAt': 1700000000000,
        },
      });
      // playCount is server-maintained and rejected by the security rules on create.
      expect(document.containsKey('playCount'), isFalse);
    });

    test('a written document maps back to the same chant', () {
      final document = adminChantToFirestore(
        chantId: 'heart-sutra',
        name: 'Heart Sutra',
        order: 3,
        audio: audio,
        lyrics: lyrics,
        cover: cover,
        updatedAt: updatedAt,
      );
      final chant = adminChantFromFirestore('heart-sutra', Map<String, dynamic>.from(document));

      expect(chant.length, const Duration(seconds: 185));
      expect(chant.isLoadableByMobileApp, isTrue);
      expect(chant.cover, const AdminChantAssetEntity(version: 1, sha256: 'ccc', bytes: 1024));
    });

    test('replacing audio bumps its version and updates the length only', () {
      final update = adminChantAssetUpdateToFirestore(chantId: 'heart-sutra', asset: audio, updatedAt: updatedAt);

      expect(update.keys, {
        'metaData.id',
        'metaData.audioVersion',
        'metaData.audioSha256',
        'metaData.audioBytes',
        'metaData.updatedAt',
        'length',
      });
      expect(update['metaData.audioVersion'], isA<FieldValue>());
      expect(update['metaData.audioSha256'], 'aaa');
      expect(update['metaData.audioBytes'], 2048);
      expect(update['length'], 185);
    });

    test('replacing the cover updates the blurHash, lyrics touch metadata only', () {
      final coverUpdate = adminChantAssetUpdateToFirestore(chantId: 'x', asset: cover, updatedAt: updatedAt);
      final lyricsUpdate = adminChantAssetUpdateToFirestore(chantId: 'x', asset: lyrics, updatedAt: updatedAt);

      expect(coverUpdate['blurHash'], 'LEHV6n');
      expect(coverUpdate.containsKey('length'), isFalse);
      expect(lyricsUpdate.keys.where((key) => !key.startsWith('metaData.')), isEmpty);
    });
  });
}
