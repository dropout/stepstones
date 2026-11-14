import 'package:chanting/src/domain/entity/chant_cache_entity.dart';
import 'package:chant_schema/chant_schema.dart';
import 'package:chanting/src/domain/enum/cache_download_state.dart';

ChantEntity chantFixture(String id) => ChantEntity(
  id: id,
  name: id,
  blurHash: '',
  length: const Duration(minutes: 1),
  metaData: ChantMetaDataEntity(
    id: id,
    audioVersion: 2,
    lyricsVersion: 2,
    coverVersion: 1,
    audioSha256: 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    lyricsSha256: 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    coverSha256: '',
    audioBytes: 3,
    lyricsBytes: 3,
    coverBytes: 0,
    updatedAt: DateTime.utc(2025),
  ),
);

ChantCacheEntity cacheEntryFixture(String id, ChantAssetType type, String path, {int version = 1}) => ChantCacheEntity(
  id: '$id:${type.name}',
  contentId: id,
  assetType: type,
  storagePath: '/chants/$id/${type.fileName}',
  localFilePath: path,
  cachedVersion: version,
  remoteUpdatedAtEpochMs: 1,
  isValid: true,
  downloadState: CacheDownloadState.complete,
  failureCount: 3,
  createdAtEpochMs: 42,
  updatedAtEpochMs: 43,
);
