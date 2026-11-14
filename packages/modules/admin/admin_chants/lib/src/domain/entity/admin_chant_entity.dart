import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin_chants/src/domain/entity/admin_chant_asset_entity.dart';

part 'admin_chant_entity.freezed.dart';

@freezed
sealed class AdminChantEntity with _$AdminChantEntity {
  const AdminChantEntity._();

  const factory AdminChantEntity({
    required String id,
    required String name,
    @Default(0) int order,
    @Default(Duration.zero) Duration length,
    @Default(0) int playCount,
    String? blurHash,
    @Default(AdminChantAssetEntity()) AdminChantAssetEntity audio,
    @Default(AdminChantAssetEntity()) AdminChantAssetEntity lyrics,
    @Default(AdminChantAssetEntity()) AdminChantAssetEntity cover,
    DateTime? assetsUpdatedAt,
    // False when the mobile app's chant model cannot parse the document.
    @Default(true) bool isLoadableByMobileApp,
  }) = _AdminChantEntity;
}
