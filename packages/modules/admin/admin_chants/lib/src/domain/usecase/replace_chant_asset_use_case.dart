import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/repository/admin_chant_repository.dart';
import 'package:admin_chants/src/domain/service/chant_asset_preparer.dart';

class ReplaceChantAssetUseCase {
  final ChantAssetPreparer chantAssetPreparer;
  final AdminChantRepository adminChantRepository;

  const ReplaceChantAssetUseCase({required this.chantAssetPreparer, required this.adminChantRepository});

  Future<void> execute({required String chantId, required ChantAssetType type, required String path}) async {
    final asset = await chantAssetPreparer.prepare(type, path);
    await adminChantRepository.replaceChantAsset(chantId: chantId, asset: asset);
  }
}
