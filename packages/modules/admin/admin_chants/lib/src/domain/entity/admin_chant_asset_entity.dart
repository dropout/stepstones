import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_chant_asset_entity.freezed.dart';

@freezed
sealed class AdminChantAssetEntity with _$AdminChantAssetEntity {
  const factory AdminChantAssetEntity({@Default(0) int version, @Default('') String sha256, @Default(0) int bytes}) =
      _AdminChantAssetEntity;
}
