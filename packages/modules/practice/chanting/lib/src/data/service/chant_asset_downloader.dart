import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:chanting/src/data/service/chant_cache_file_system.dart';
import 'package:chanting/src/data/service/file_validation_extension.dart';
import 'package:chanting/src/domain/entity/cache_validation_result_entity.dart';
import 'package:chanting/src/domain/entity/caching_progress_entity.dart';
import 'package:chanting/src/domain/entity/chant_cache_entity.dart';
import 'package:chanting/src/domain/entity/chant_entity.dart';
import 'package:chanting/src/domain/enum/cache_download_state.dart';
import 'package:chanting/src/domain/enum/cached_asset_type.dart';
import 'package:chanting/src/domain/repository/chant_cache_data_repository.dart';
import 'package:chanting/src/domain/service/chant_cache_services.dart';
import 'package:clock/clock.dart';
import 'package:core/core.dart';
import 'package:firebase_provider/firebase_provider.dart';

typedef _PendingDownload = ({DownloadTask task, ChantCacheEntity entry});

class ChantAssetDownloader with LoggerMixin implements ChantAssetDownloadService {
  final ChantCacheRepository chantCacheRepo;
  final ChantCacheFileSystem chantCacheFileSystem;
  final StorageDataProvider storageDataProvider;

  ChantAssetDownloader({
    required this.chantCacheRepo,
    required this.chantCacheFileSystem,
    required this.storageDataProvider,
  });

  @override
  Stream<CachingProgressEntity> download(List<CacheValidationResultEntity> chants) async* {
    final pending = <_PendingDownload>[];
    final validations = <Future<void>>[];
    final subscriptions = <StreamSubscription<TaskSnapshot>>[];
    final progressController = StreamController<CachingProgressEntity>();
    var finished = false;
    var closing = false;
    var validationFailed = false;

    try {
      void trackDownload(_PendingDownload item) {
        pending.add(item);
        validations.add(
          _validateDownload(item).then(
            (_) {},
            onError: (Object error, StackTrace stack) {
              validationFailed = true;
              if (!closing && !progressController.isClosed) {
                progressController.addError(error, stack);
              }
            },
          ),
        );
      }

      for (final result in chants) {
        if (!result.isAudioCacheValid) {
          trackDownload(await _startDownload(result.chant, CachedAssetType.audio, result.audioCacheEntry));
        }
        if (!result.isLyricsCacheValid) {
          trackDownload(await _startDownload(result.chant, CachedAssetType.lyrics, result.lyricsCacheEntry));
        }
      }

      if (pending.isEmpty) {
        throw StateError('No invalid chant assets to download.');
      }

      void reportProgress() {
        if (closing || progressController.isClosed) return;
        final totalBytes = pending.fold<int>(0, (sum, item) => sum + item.task.snapshot.totalBytes);
        final transferred = pending.fold<int>(0, (sum, item) => sum + item.task.snapshot.bytesTransferred);
        progressController.add(
          CachingProgressEntity(
            progress: totalBytes == 0 ? 0 : min(transferred / totalBytes, 0.99),
            totalTasks: pending.length,
            completedTasks: pending.where((item) => item.task.snapshot.state == TaskState.success).length,
          ),
        );
      }

      for (final item in pending) {
        subscriptions.add(
          item.task.snapshotEvents.listen(
            (_) => reportProgress(),
            onError: (Object error, StackTrace stack) {
              if (!closing && !progressController.isClosed) progressController.addError(error, stack);
            },
          ),
        );
      }

      unawaited(
        Future.wait(validations).then((_) {
          finished = true;
          if (!closing && !progressController.isClosed) {
            if (!validationFailed) reportProgress();
            unawaited(progressController.close());
          }
        }),
      );

      yield* progressController.stream;
    } finally {
      closing = true;
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      if (!finished) {
        for (final item in pending) {
          if (item.task.snapshot.state == TaskState.running || item.task.snapshot.state == TaskState.paused) {
            await item.task.cancel();
          }
        }
      }
      await Future.wait(validations);
      if (!progressController.isClosed) unawaited(progressController.close());
    }
  }

  Future<_PendingDownload> _startDownload(
    ChantEntity chant,
    CachedAssetType assetType,
    ChantCacheEntity? existing,
  ) async {
    final metadata = chant.metaData;
    final destinationPath = await chantCacheFileSystem.buildCacheFilePath(
      contentId: chant.id,
      assetType: assetType,
      version: metadata.getVersion(assetType),
    );

    try {
      if (existing != null) await File(existing.localFilePath).deleteIfExists();

      final now = clock.now().millisecondsSinceEpoch;
      final entry = ChantCacheEntity(
        id: '${chant.id}:${assetType.name}',
        contentId: chant.id,
        assetType: assetType,
        storagePath: metadata.getStoragePath(assetType),
        localFilePath: destinationPath,
        cachedVersion: metadata.getVersion(assetType),
        remoteUpdatedAtEpochMs: metadata.updatedAt.millisecondsSinceEpoch,
        remoteHash: metadata.getHash(assetType),
        remoteBytes: metadata.getBytes(assetType),
        downloadState: CacheDownloadState.downloading,
        failureCount: existing?.failureCount ?? 0,
        createdAtEpochMs: existing?.createdAtEpochMs ?? now,
        updatedAtEpochMs: now,
      );
      await chantCacheRepo.upsertEntry(entry);
      final task = await storageDataProvider.downloadFile(
        storagePath: entry.storagePath,
        destinationPath: destinationPath,
      );
      return (task: task, entry: entry);
    } catch (error) {
      await _markFailed(chant.id, assetType, destinationPath, error);
      rethrow;
    }
  }

  Future<void> _validateDownload(_PendingDownload pending) async {
    final entry = pending.entry;
    try {
      await pending.task;
      final file = File(entry.localFilePath);
      final hash = await file.sha256();
      final bytes = await file.size();
      if (hash.isNotEmpty && entry.remoteHash != hash) {
        throw const FileSystemException('Downloaded file hash mismatch.');
      }
      if (entry.remoteBytes != bytes) {
        throw const FileSystemException('Downloaded file size mismatch.');
      }

      final now = clock.now().millisecondsSinceEpoch;
      await chantCacheRepo.upsertEntry(
        entry.copyWith(
          isValid: true,
          downloadState: CacheDownloadState.complete,
          remoteHash: hash,
          remoteBytes: bytes,
          lastValidatedAtEpochMs: now,
          updatedAtEpochMs: now,
        ),
      );
    } catch (error) {
      await _markFailed(entry.contentId, entry.assetType, entry.localFilePath, error);
      rethrow;
    }
  }

  Future<void> _markFailed(String contentId, CachedAssetType assetType, String path, Object error) async {
    try {
      await chantCacheRepo.markState(
        contentId: contentId,
        assetType: assetType,
        state: CacheDownloadState.failed,
        lastError: error.toString(),
      );
    } finally {
      await File(path).deleteIfExists();
    }
  }
}
