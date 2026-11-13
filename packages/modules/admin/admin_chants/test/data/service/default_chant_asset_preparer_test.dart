import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:admin_chants/src/data/service/default_chant_asset_preparer.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/failure/chant_failure.dart';

void main() {
  late Directory directory;

  DefaultChantAssetPreparer preparer({
    Future<Duration> Function(Uint8List)? readAudioLength,
    String Function(Uint8List)? encodeBlurHash,
  }) => DefaultChantAssetPreparer(
    readAudioLength: readAudioLength ?? (_) async => const Duration(milliseconds: 185400),
    encodeBlurHash: encodeBlurHash ?? (_) => 'LEHV6n',
  );

  Future<String> write(String name, List<int> bytes) async {
    final file = File('${directory.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Matcher failsWith(ChantFailureReason reason) =>
      throwsA(isA<ChantFailure>().having((failure) => failure.reason, 'reason', reason));

  setUp(() => directory = Directory.systemTemp.createTempSync('admin_chants_test'));
  tearDown(() => directory.deleteSync(recursive: true));

  test('hashes the content and reports its size', () async {
    final asset = await preparer().prepare(ChantAssetType.lyrics, await write('a.ass', 'abc'.codeUnits));

    expect(asset.type, ChantAssetType.lyrics);
    expect(asset.bytes, 'abc'.codeUnits);
    expect(asset.sha256, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    expect(asset.length, isNull);
    expect(asset.blurHash, isNull);
  });

  test('audio gets its length rounded to whole seconds', () async {
    final asset = await preparer().prepare(ChantAssetType.audio, await write('a.mp3', [1, 2, 3]));
    expect(asset.length, const Duration(seconds: 185));
  });

  test('very short audio is stored as one second', () async {
    final asset = await preparer(readAudioLength: (_) async => const Duration(milliseconds: 300))
        .prepare(ChantAssetType.audio, await write('a.mp3', [1]));
    expect(asset.length, const Duration(seconds: 1));
  });

  test('the cover gets a blurHash', () async {
    final asset = await preparer().prepare(ChantAssetType.cover, await write('c.jpg', [1, 2, 3]));
    expect(asset.blurHash, 'LEHV6n');
  });

  test('rejects missing, empty and undecodable files', () async {
    await expectLater(
      preparer().prepare(ChantAssetType.audio, '${directory.path}/missing.mp3'),
      failsWith(.unreadableAsset),
    );
    await expectLater(preparer().prepare(ChantAssetType.audio, await write('e.mp3', [])), failsWith(.emptyFile));
    await expectLater(
      preparer(readAudioLength: (_) async => throw Exception('not audio'))
          .prepare(ChantAssetType.audio, await write('bad.mp3', [1])),
      failsWith(.unreadableAsset),
    );
    await expectLater(
      preparer(readAudioLength: (_) async => Duration.zero).prepare(ChantAssetType.audio, await write('z.mp3', [1])),
      failsWith(.unreadableAsset),
    );
  });

  test('rejects a cover the real encoder cannot decode', () async {
    const real = DefaultChantAssetPreparer(readAudioLength: _noAudio);
    await expectLater(
      real.prepare(ChantAssetType.cover, await write('c.jpg', 'not an image'.codeUnits)),
      failsWith(.unreadableAsset),
    );
  });
}

Future<Duration> _noAudio(Uint8List _) async => Duration.zero;
