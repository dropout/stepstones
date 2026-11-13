import 'package:admin_chants/src/domain/entity/prepared_chant_asset_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';

abstract interface class ChantAssetPreparer {
  /// Reads the file and derives hash, size, audio length and cover blurHash; throws ChantFailure if unusable.
  Future<PreparedChantAssetEntity> prepare(ChantAssetType type, String path);
}
