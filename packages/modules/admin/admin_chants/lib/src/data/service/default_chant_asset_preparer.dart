import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'package:admin_chants/src/domain/entity/prepared_chant_asset_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/failure/chant_failure.dart';
import 'package:admin_chants/src/domain/service/chant_asset_preparer.dart';

typedef AudioLengthReader = Future<Duration> Function(Uint8List audioBytes);
typedef BlurHashEncoder = String Function(Uint8List imageBytes);

class DefaultChantAssetPreparer implements ChantAssetPreparer {
  final AudioLengthReader readAudioLength;
  final BlurHashEncoder encodeBlurHash;

  const DefaultChantAssetPreparer({required this.readAudioLength, this.encodeBlurHash = createBlurHash});

  @override
  Future<PreparedChantAssetEntity> prepare(ChantAssetType type, String path) async {
    final Uint8List bytes;
    try {
      bytes = await File(path).readAsBytes();
    } on FileSystemException {
      throw const ChantFailure(.unreadableAsset);
    }
    if (bytes.isEmpty) throw const ChantFailure(.emptyFile);

    return PreparedChantAssetEntity(
      type: type,
      bytes: bytes,
      sha256: crypto.sha256.convert(bytes).toString(),
      length: type == .audio ? await _audioLength(bytes) : null,
      blurHash: type == .cover ? _blurHash(bytes) : null,
    );
  }

  Future<Duration> _audioLength(Uint8List bytes) async {
    final Duration length;
    try {
      length = await readAudioLength(bytes);
    } catch (_) {
      throw const ChantFailure(.unreadableAsset);
    }
    if (length <= Duration.zero) throw const ChantFailure(.unreadableAsset);
    // The chant document stores whole seconds and a zero length would read as broken.
    final seconds = (length.inMilliseconds / 1000).round();
    return Duration(seconds: seconds < 1 ? 1 : seconds);
  }

  String _blurHash(Uint8List bytes) {
    try {
      final hash = encodeBlurHash(bytes);
      if (hash.isEmpty) throw const ChantFailure(.unreadableAsset);
      return hash;
    } catch (_) {
      throw const ChantFailure(.unreadableAsset);
    }
  }
}
