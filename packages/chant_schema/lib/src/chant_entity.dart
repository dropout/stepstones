import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:chant_schema/src/chant_meta_data_entity.dart';

part 'chant_entity.freezed.dart';
part 'chant_entity.g.dart';

/// A `chants/{id}` document; every required field must be present for the mobile app to load the chant.
@freezed
sealed class ChantEntity with _$ChantEntity implements SerializableEntity {
  const ChantEntity._();

  // Nested maps are needed to write the document, not only to read it.
  @JsonSerializable(explicitToJson: true)
  const factory ChantEntity({
    required String id,
    required String name,
    required ChantMetaDataEntity metaData,
    required String blurHash,
    @Default(0) int order,
    @DurationConverter() required Duration length,
  }) = _ChantEntity;

  factory ChantEntity.fromJson(Map<String, Object?> json) => _$ChantEntityFromJson(json);
}
