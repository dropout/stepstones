import 'package:core/core.dart';
import 'package:chanting/src/domain/entity/cache_validation_result_entity.dart';
import 'package:chanting/src/domain/entity/chant_cache_entity.dart';
import 'package:chanting/src/domain/enum/cached_asset_type.dart';
import 'package:chanting/src/domain/entity/chant_entity.dart';
import 'package:chanting/src/domain/repository/chant_cache_data_repository.dart';
import 'package:chanting/src/domain/service/chant_cache_services.dart';
import 'package:clock/clock.dart';

typedef AssetValidationResult = ({bool isValid, String? localAssetPath, ChantCacheEntity? entry});

class ChantCacheValidator with LoggerMixin implements ChantCacheValidationService {
  final ChantCacheRepository chantCacheRepo;
  final ChantCacheFileAccess fileAccess;

  ChantCacheValidator({required this.chantCacheRepo, required this.fileAccess});

  @override
  Future<CacheValidationResultEntity> validate(ChantEntity chant) async {
    logger.t('Validating cache for chant: ${chant.id} - ${chant.name}');

    final audioAssetValidation = await validateChantAssetCache(
      chant: chant,
      type: .audio,
      chantCacheRepo: chantCacheRepo,
    );

    final lyricsAssetValidation = await validateChantAssetCache(
      chant: chant,
      type: .lyrics,
      chantCacheRepo: chantCacheRepo,
    );

    return CacheValidationResultEntity(
      chant: chant,
      isAudioCacheValid: audioAssetValidation.isValid,
      isLyricsCacheValid: lyricsAssetValidation.isValid,
      audioCachePath: audioAssetValidation.localAssetPath,
      lyricsCachePath: lyricsAssetValidation.localAssetPath,
      audioCacheEntry: audioAssetValidation.entry,
      lyricsCacheEntry: lyricsAssetValidation.entry,
    );
  }

  Future<AssetValidationResult> validateChantAssetCache({
    required ChantEntity chant,
    required CachedAssetType type,
    required ChantCacheRepository chantCacheRepo,
  }) async {
    // Collecting metadata for the asset from remote source
    final metadata = chant.metaData;
    final version = metadata.getVersion(type);
    final hash = metadata.getHash(type);
    final bytes = metadata.getBytes(type);
    final remoteUpdatedAt = metadata.updatedAt.millisecondsSinceEpoch;

    // Collecting existing cache entry from local database
    final existing = await chantCacheRepo.readEntry(chant.id, type);

    // If the existing entry is valid and usable, return its local file path
    if (existing != null && await isCacheDataEntryUsable(existing, version, hash, bytes)) {
      await chantCacheRepo.upsertEntry(
        existing.copyWith(
          lastValidatedAtEpochMs: clock.now().millisecondsSinceEpoch,
          remoteUpdatedAtEpochMs: remoteUpdatedAt,
        ),
      );
      return (isValid: true, localAssetPath: existing.localFilePath, entry: existing);
    }

    return (isValid: false, localAssetPath: null, entry: existing);
  }

  Future<bool> isCacheDataEntryUsable(
    ChantCacheEntity row,
    int expectedVersion,
    String? expectedHash,
    int? expectedBytes,
  ) async {
    if (!row.isValid) {
      logger.t('Cache entry ${row.id} is marked as invalid.');
      return false;
    }

    if (row.cachedVersion != expectedVersion) {
      logger.t('Cache entry ${row.id} version mismatch: expected $expectedVersion, found ${row.cachedVersion}.');
      return false;
    }

    final fileExists = await fileAccess.exists(row.localFilePath);
    if (!fileExists) {
      logger.t('Cache entry ${row.id} file does not exist at path ${row.localFilePath}.');
      return false;
    }

    if (expectedHash != null && expectedHash.isNotEmpty) {
      final localHash = await fileAccess.sha256(row.localFilePath);
      if (localHash != expectedHash) {
        logger.t('Cache entry ${row.id} hash mismatch: expected $expectedHash, found $localHash.');
        return false;
      }
    }

    if (expectedBytes != null) {
      final localBytes = await fileAccess.size(row.localFilePath);
      if (localBytes != expectedBytes) {
        logger.t('Cache entry ${row.id} size mismatch: expected $expectedBytes, found $localBytes.');
        return false;
      }
    }

    return true;
  }
}
