import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:chant_schema/src/chant_asset_type.dart';

part 'chant_meta_data_entity.freezed.dart';
part 'chant_meta_data_entity.g.dart';

@freezed
sealed class ChantMetaDataEntity with _$ChantMetaDataEntity implements SerializableEntity {
  const ChantMetaDataEntity._();

  const factory ChantMetaDataEntity({
    required String id,
    required int audioVersion,
    required int lyricsVersion,
    required int coverVersion,
    required String audioSha256,
    required String lyricsSha256,
    required String coverSha256,
    required int audioBytes,
    required int lyricsBytes,
    required int coverBytes,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _ChantMetaDataEntity;

  factory ChantMetaDataEntity.fromJson(Map<String, Object?> json) => _$ChantMetaDataEntityFromJson(json);

  String getStoragePath(ChantAssetType type) => type.storagePath(id);

  int getVersion(ChantAssetType type) => switch (type) {
    .audio => audioVersion,
    .lyrics => lyricsVersion,
    .cover => coverVersion,
  };

  String getHash(ChantAssetType type) => switch (type) {
    .audio => audioSha256,
    .lyrics => lyricsSha256,
    .cover => coverSha256,
  };

  int getBytes(ChantAssetType type) => switch (type) {
    .audio => audioBytes,
    .lyrics => lyricsBytes,
    .cover => coverBytes,
  };
}
