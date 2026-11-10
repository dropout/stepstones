import 'package:chanting/src/domain/entity/cache_validation_result_entity.dart';
import 'package:chanting/src/domain/entity/caching_progress_entity.dart';
import 'package:chanting/src/domain/entity/chant_entity.dart';
import 'package:chanting/src/domain/entity/chant_local_resources_entity.dart';

abstract interface class ChantCacheValidationService {
  Future<CacheValidationResultEntity> validate(ChantEntity chant);
}

abstract interface class ChantCacheFileAccess {
  Future<bool> exists(String path);
  Future<String> sha256(String path);
  Future<int> size(String path);
}

abstract interface class ChantLocalResourcesService {
  Future<ChantLocalResourcesEntity> resolve(ChantEntity chant);
}

abstract interface class ChantAssetDownloadService {
  Stream<CachingProgressEntity> download(List<CacheValidationResultEntity> chants);
}
