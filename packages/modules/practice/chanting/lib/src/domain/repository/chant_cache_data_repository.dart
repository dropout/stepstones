import 'package:chanting/src/domain/entity/chant_cache_entity.dart';
import 'package:chanting/src/domain/enum/cache_download_state.dart';
import 'package:chanting/src/domain/enum/cached_asset_type.dart';

abstract interface class ChantCacheRepository {
  // ---------------------------------------------------------------------------
  // Local database operations
  // ---------------------------------------------------------------------------

  /// Reads a cache entry from the local database for the given content ID and asset type.
  Future<ChantCacheEntity?> readEntry(String contentId, CachedAssetType type);

  Future<void> markState({
    required String contentId,
    required CachedAssetType assetType,
    required CacheDownloadState state,
    String? lastError,
  });

  /// Upserts a cache entry in the local database.
  Future<void> upsertEntry(ChantCacheEntity entry);

  /// Deletes a cache entry from the local database for the given content ID and asset type.
  Future<void> deleteEntry(String contentId, CachedAssetType type);

  /// Deletes all cache entries from the local database.
  Future<void> deleteAllEntries();

  // ---------------------------------------------------------------------------
  // File system operations
  // ---------------------------------------------------------------------------

  /// Ensures that the root cache directory exists.
  Future<void> ensureCacheDirectories();

  /// Clears all cached files and directories.
  Future<void> clearCache();
}
