import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';

part 'prepared_chant_asset_entity.freezed.dart';

/// A chant file read from disk together with the metadata derived from its content.
@freezed
sealed class PreparedChantAssetEntity with _$PreparedChantAssetEntity {
  const factory PreparedChantAssetEntity({
    required ChantAssetType type,
    required Uint8List bytes,
    required String sha256,
    // Only set for audio.
    Duration? length,
    // Only set for the cover.
    String? blurHash,
  }) = _PreparedChantAssetEntity;
}
