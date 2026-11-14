import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_presence_location_entity.freezed.dart';

/// Number of present profiles at one location; a null name groups profiles that share no location.
@freezed
sealed class AdminPresenceLocationEntity with _$AdminPresenceLocationEntity {
  const factory AdminPresenceLocationEntity({required String? name, required int count}) = _AdminPresenceLocationEntity;
}
