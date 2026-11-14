import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_presence_entity.freezed.dart';

@freezed
sealed class AdminPresenceEntity with _$AdminPresenceEntity {
  const AdminPresenceEntity._();

  const factory AdminPresenceEntity({
    required String profileId,
    @Default('') String firstName,
    @Default('') String lastName,
    required DateTime startedAt,
    String? locationName,
  }) = _AdminPresenceEntity;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? profileId : name;
  }
}
