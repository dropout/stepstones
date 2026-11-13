import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/entity/prepared_chant_asset_entity.dart';

abstract interface class AdminChantRepository {
  /// Emits the catalog sorted by order, and again on every change.
  Stream<List<AdminChantEntity>> watchChants();

  Future<void> renameChant({required String chantId, required String name});

  /// Persists the position of each id in [orderedChantIds] as its order.
  Future<void> reorderChants(List<String> orderedChantIds);

  /// Uploads all three assets and creates the chant; throws ChantFailure(duplicateId) if the id is taken.
  Future<void> createChant({
    required String chantId,
    required String name,
    required int order,
    required PreparedChantAssetEntity audio,
    required PreparedChantAssetEntity lyrics,
    required PreparedChantAssetEntity cover,
  });

  /// Uploads the file and bumps the asset version so mobile caches re-download it.
  Future<void> replaceChantAsset({required String chantId, required PreparedChantAssetEntity asset});
}
