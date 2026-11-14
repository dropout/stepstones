import 'package:chant_schema/chant_schema.dart';
import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chant_meta_data.freezed.dart';
part 'chant_meta_data.g.dart';

@freezed
sealed class ChantMetaData with _$ChantMetaData implements SerializableEntity {
  const ChantMetaData._();

  const factory ChantMetaData({
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
  }) = _ChantMetaData;

  factory ChantMetaData.fromJson(Map<String, Object?> json) =>
      _$ChantMetaDataFromJson(json);

  String getStoragePath(ChantAssetType type) {
    switch (type) {
      case ChantAssetType.audio:
        return '/chants/$id/${type.fileName}';
      case ChantAssetType.lyrics:
        return '/chants/$id/${type.fileName}';
      case ChantAssetType.cover:
        return '/chants/$id/${type.fileName}';
    }
  }

  int getVersion(ChantAssetType type) {
    switch (type) {
      case ChantAssetType.audio:
        return audioVersion;
      case ChantAssetType.lyrics:
        return lyricsVersion;
      case ChantAssetType.cover:
        return coverVersion;
    }
  }

  String getHash(ChantAssetType type) {
    switch (type) {
      case ChantAssetType.audio:
        return audioSha256;
      case ChantAssetType.lyrics:
        return lyricsSha256;
      case ChantAssetType.cover:
        return coverSha256;
    }
  }

  int getBytes(ChantAssetType type) {
    switch (type) {
      case ChantAssetType.audio:
        return audioBytes;
      case ChantAssetType.lyrics:
        return lyricsBytes;
      case ChantAssetType.cover:
        return coverBytes;
    }
  }
}
