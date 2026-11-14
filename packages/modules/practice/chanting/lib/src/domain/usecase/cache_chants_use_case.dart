import 'package:core/core.dart';
import 'package:chanting/src/domain/entity/cache_validation_result_entity.dart';
import 'package:chanting/src/domain/entity/caching_progress_entity.dart';
import 'package:chant_schema/chant_schema.dart';
import 'package:chanting/src/domain/entity/chant_local_resources_entity.dart';
import 'package:chanting/src/domain/repository/chant_cache_data_repository.dart';
import 'package:chanting/src/domain/service/chant_cache_services.dart';

/// Ensures the requested chants are cached locally,
/// streaming progress as assets are downloaded.
class CacheChantsUseCase with LoggerMixin {
  final ChantCacheRepository chantCacheRepo;
  final ChantCacheValidationService chantCacheValidator;
  final ChantAssetDownloadService chantAssetDownloader;
  final ChantLocalResourcesService localResourceResolver;

  CacheChantsUseCase({
    required this.chantCacheRepo,
    required this.chantCacheValidator,
    required this.chantAssetDownloader,
    required this.localResourceResolver,
  });

  Stream<CachingProgressEntity> execute(List<String> chantIds, List<ChantEntity> availableChants) async* {
    logger.t('Preparing playable assets for ${chantIds.length} chants...');

    await chantCacheRepo.ensureCacheDirectories();

    // Only process unique chant IDs to avoid redundant work
    final uniqueIds = chantIds.toSet().toList(growable: false);

    // Check if chants are already cached and valid
    final List<CacheValidationResultEntity> validationResults = [];
    for (final contentId in uniqueIds) {
      final chant = availableChants.firstWhere(
        (chant) => chant.id == contentId,
        orElse: () => throw StateError('Chant with ID $contentId not found in available chants.'),
      );
      final validationResult = await chantCacheValidator.validate(chant);
      validationResults.add(validationResult);
    }

    // Collect invalid chants that need to be cached
    final invalidChants = validationResults.where((validationResult) => (validationResult.isValid == false)).toList();

    // If there are no invalid chants, yield a final progress update with all
    // the prepared chant local resources
    if (invalidChants.isEmpty) {
      logger.t('All chant cache entries are valid. No caching needed.');

      final results = await _buildResults(chantIds, validationResults);
      yield CachingProgressEntity(
        progress: 1.0,
        totalTasks: results.length,
        completedTasks: results.length,
        results: results,
      );
      return;
    }

    logger.t('Found ${invalidChants.length} chant(s) with invalid cache. Caching chant assets now...');

    CachingProgressEntity? downloadProgress;
    await for (final progress in chantAssetDownloader.download(invalidChants)) {
      downloadProgress = progress;
      yield progress.copyWith(progress: progress.progress.clamp(0.0, 0.99), results: []);
    }
    if (downloadProgress == null ||
        downloadProgress.totalTasks == 0 ||
        downloadProgress.completedTasks != downloadProgress.totalTasks) {
      throw StateError('Chant asset downloads did not complete.');
    }

    // Yield a final progress update with all the prepared chant local resources
    final results = await _buildResults(chantIds, validationResults);

    if (results.length != chantIds.length) {
      throw StateError(
        'Mismatch between requested chant IDs and collected local resources. '
        'Requested: ${chantIds.length}, Collected: ${results.length}',
      );
    }

    yield CachingProgressEntity(
      progress: 1.0,
      totalTasks: downloadProgress.totalTasks,
      completedTasks: downloadProgress.completedTasks,
      results: results,
    );
    logger.t('All chant assets have been cached and validated successfully.');
  }

  /// Builds the local resources for every requested chant ID from already-computed validation results.
  Future<List<({ChantEntity chant, ChantLocalResourcesEntity localResources})>> _buildResults(
    List<String> chantIds,
    List<CacheValidationResultEntity> validationResults,
  ) async {
    final results = <({ChantEntity chant, ChantLocalResourcesEntity localResources})>[];
    for (final chantId in chantIds) {
      final chant = validationResults.firstWhere((result) => result.chant.id == chantId).chant;
      results.add((chant: chant, localResources: await localResourceResolver.resolve(chant)));
    }
    return results;
  }
}
