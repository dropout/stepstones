import 'package:chanting/src/domain/enum/cache_download_state.dart';
import 'package:chant_schema/chant_schema.dart';
import 'package:chanting/src/drift/chant_cache_database.dart';

abstract interface class ChantCacheDataProvider {
  Future<ChantCacheEntryRow?> readEntry(String contentId, ChantAssetType type);
  Future<void> upsertEntry(ChantCacheEntryRow row);

  Future<void> markState({
    required String contentId,
    required ChantAssetType assetType,
    required CacheDownloadState state,
    String? lastError,
  });

  Future<void> deleteEntry(String contentId, ChantAssetType type);
  Future<void> deleteAllEntries();
}
