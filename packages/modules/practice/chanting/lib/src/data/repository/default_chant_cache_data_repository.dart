import 'package:chanting/src/domain/enum/cache_download_state.dart';
import 'package:chanting/src/domain/enum/cached_asset_type.dart';
import 'package:chanting/src/domain/entity/chant_cache_entity.dart';
import 'package:chanting/src/data/mapper/chant_cache_mapper.dart';
import 'package:core/core.dart';
import 'package:chanting/src/data/datasource/chant_cache_data_provider.dart';
import 'package:chanting/src/data/service/chant_cache_file_system.dart';
import 'package:chanting/src/domain/repository/chant_cache_data_repository.dart';

class DefaultChantCacheDataRepository with LoggerMixin implements ChantCacheRepository {
  final ChantCacheDataProvider chantCacheDataProvider;
  final ChantCacheFileSystem chantCacheFileSystem;

  DefaultChantCacheDataRepository({required this.chantCacheDataProvider, required this.chantCacheFileSystem});

  @override
  Future<ChantCacheEntity?> readEntry(String contentId, CachedAssetType type) async =>
      (await chantCacheDataProvider.readEntry(contentId, type))?.toDomain();

  @override
  Future<void> upsertEntry(ChantCacheEntity entry) async => chantCacheDataProvider.upsertEntry(entry.toRow());

  @override
  Future<void> markState({
    required String contentId,
    required CachedAssetType assetType,
    required CacheDownloadState state,
    String? lastError,
  }) async {
    await chantCacheDataProvider.markState(
      contentId: contentId,
      assetType: assetType,
      state: state,
      lastError: lastError,
    );
  }

  @override
  Future<void> deleteEntry(String contentId, CachedAssetType type) async =>
      await chantCacheDataProvider.deleteEntry(contentId, type);

  @override
  Future<void> deleteAllEntries() async => await chantCacheDataProvider.deleteAllEntries();

  @override
  Future<void> ensureCacheDirectories() async => chantCacheFileSystem.ensureCacheDirectories();

  @override
  Future<void> clearCache() async => chantCacheFileSystem.clearCache();
}
