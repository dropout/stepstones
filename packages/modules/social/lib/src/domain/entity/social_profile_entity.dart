import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';


part 'social_profile_entity.freezed.dart';
part 'social_profile_entity.g.dart';

@freezed
sealed class SocialProfileEntity with _$SocialProfileEntity {

  const SocialProfileEntity._();

  @JsonSerializable(explicitToJson: true)
  const factory SocialProfileEntity({
    required String id,
    required String firstName,
    required String lastName,
    required String? photoBlurhash,
    Location? location,
  }) = _SocialProfileEntity;

  factory SocialProfileEntity.anonymous() {
    return SocialProfileEntity(
      id: const Uuid().v4(),
      firstName: DefaultProfileData.firstName,
      lastName: DefaultProfileData.lastName,
      photoBlurhash: DefaultProfileData.photoBlurhash,
    );
  }

  factory SocialProfileEntity.fromJson(Map<String, Object?> json) =>
    _$SocialProfileEntityFromJson(json);  

}
