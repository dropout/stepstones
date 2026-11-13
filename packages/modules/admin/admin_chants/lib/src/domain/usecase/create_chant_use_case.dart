import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/failure/chant_failure.dart';
import 'package:admin_chants/src/domain/repository/admin_chant_repository.dart';
import 'package:admin_chants/src/domain/service/chant_asset_preparer.dart';

class CreateChantUseCase {
  static const maxNameLength = 100;
  static const maxIdLength = 64;

  // The id becomes a document id and a storage folder, so it stays a plain lowercase slug.
  static final _idPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

  final ChantAssetPreparer chantAssetPreparer;
  final AdminChantRepository adminChantRepository;

  const CreateChantUseCase({required this.chantAssetPreparer, required this.adminChantRepository});

  /// Suggests an id for [name], e.g. "Heart Sutra" -> "heart-sutra".
  static String suggestId(String name) {
    final slug = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.length > maxIdLength ? slug.substring(0, maxIdLength).replaceAll(RegExp(r'-+$'), '') : slug;
  }

  Future<void> execute({
    required String name,
    required String chantId,
    required Map<ChantAssetType, String> filePaths,
    required List<AdminChantEntity> existingChants,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw const ChantFailure(.emptyName);
    if (trimmedName.length > maxNameLength) throw const ChantFailure(.nameTooLong);
    if (chantId.length > maxIdLength || !_idPattern.hasMatch(chantId)) throw const ChantFailure(.invalidId);
    if (existingChants.any((chant) => chant.id == chantId)) throw const ChantFailure(.duplicateId);
    if (ChantAssetType.values.any((type) => !filePaths.containsKey(type))) throw const ChantFailure(.missingFile);

    final audio = await chantAssetPreparer.prepare(.audio, filePaths[ChantAssetType.audio]!);
    final lyrics = await chantAssetPreparer.prepare(.lyrics, filePaths[ChantAssetType.lyrics]!);
    final cover = await chantAssetPreparer.prepare(.cover, filePaths[ChantAssetType.cover]!);

    final lastOrder = existingChants.fold<int>(-1, (max, chant) => chant.order > max ? chant.order : max);

    await adminChantRepository.createChant(
      chantId: chantId,
      name: trimmedName,
      order: lastOrder + 1,
      audio: audio,
      lyrics: lyrics,
      cover: cover,
    );
  }
}
