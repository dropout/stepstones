import 'package:core/core.dart';
import 'package:chanting/src/domain/entity/chant_cache_entity.dart';
import 'package:chant_schema/chant_schema.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cache_validation_result_entity.freezed.dart';
part 'cache_validation_result_entity.g.dart';

@freezed
sealed class CacheValidationResultEntity
    with _$CacheValidationResultEntity
    implements SerializableEntity {
  const CacheValidationResultEntity._();

  const factory CacheValidationResultEntity({
    required ChantEntity chant,
    required bool isAudioCacheValid,
    required bool isLyricsCacheValid,
    String? audioCachePath,
    String? lyricsCachePath,
    ChantCacheEntity? audioCacheEntry,
    ChantCacheEntity? lyricsCacheEntry,
  }) = _CacheValidationResultEntity;

  factory CacheValidationResultEntity.fromJson(Map<String, Object?> json) =>
      _$CacheValidationResultEntityFromJson(json);

  @override
  String get id => chant.id;

  bool get isValid => isAudioCacheValid && isLyricsCacheValid;

  bool getAssetValidity(ChantAssetType type) => switch (type) {
    .audio => isAudioCacheValid,
    .lyrics => isLyricsCacheValid,
    _ => false,
  };

  ChantCacheEntity? getCacheEntryForType(ChantAssetType type) =>
      switch (type) {
        .audio => audioCacheEntry,
        .lyrics => lyricsCacheEntry,
        _ => null,
      };

  String? getCachePathForType(ChantAssetType type) => switch (type) {
    .audio => audioCachePath,
    .lyrics => lyricsCachePath,
    _ => null,
  };
}
