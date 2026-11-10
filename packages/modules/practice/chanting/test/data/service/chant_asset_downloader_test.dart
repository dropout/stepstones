import 'dart:async';
import 'dart:io';

import 'package:chanting/src/data/service/chant_asset_downloader.dart';
import 'package:chanting/src/data/service/chant_cache_file_system.dart';
import 'package:chanting/src/data/service/chant_local_resource_resolver.dart';
import 'package:chanting/src/domain/entity/cache_validation_result_entity.dart';
import 'package:chanting/src/domain/entity/chant_cache_entity.dart';
import 'package:chanting/src/domain/enum/cache_download_state.dart';
import 'package:chanting/src/domain/enum/cached_asset_type.dart';
import 'package:chanting/src/domain/repository/chant_cache_data_repository.dart';
import 'package:chanting/src/domain/service/chant_cache_validator.dart';
import 'package:chanting/src/domain/usecase/cache_chants_use_case.dart';
import 'package:core/core.dart';
import 'package:firebase_provider/firebase_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/cache_fixtures.dart';

class MockCacheRepository extends Mock implements ChantCacheRepository {}

class MockStorage extends Mock implements StorageDataProvider {}

class FakeSnapshot extends Fake implements TaskSnapshot {
  @override
  TaskState state = TaskState.running;
  @override
  int totalBytes = 3;
  @override
  int bytesTransferred = 0;
}

class FakeDownloadTask extends Fake implements DownloadTask {
  final FakeSnapshot currentSnapshot = FakeSnapshot();
  final Completer<TaskSnapshot> completion = Completer<TaskSnapshot>();
  final Completer<void> listening = Completer<void>();
  late final StreamController<TaskSnapshot> events = StreamController<TaskSnapshot>.broadcast(
    onListen: () => listening.complete(),
  );

  @override
  TaskSnapshot get snapshot => currentSnapshot;

  @override
  Stream<TaskSnapshot> get snapshotEvents => events.stream;

  @override
  Future<T> then<T>(FutureOr<T> Function(TaskSnapshot) onValue, {Function? onError}) =>
      completion.future.then(onValue, onError: onError);

  @override
  Future<bool> cancel() async {
    currentSnapshot.state = TaskState.canceled;
    if (!completion.isCompleted) completion.completeError(StateError('cancelled'));
    return true;
  }

  void succeed() {
    currentSnapshot.state = TaskState.success;
    currentSnapshot.bytesTransferred = 3;
    events.add(currentSnapshot);
    completion.complete(currentSnapshot);
  }
}

void main() {
  test('replacement receives existing entry, removes old file and retains its metadata', () async {
    final directory = await Directory.systemTemp.createTemp('chant-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final oldFile = File('${directory.path}/old.mp3');
    await oldFile.writeAsString('old');
    final chant = chantFixture('chant');
    final oldEntry = cacheEntryFixture('chant', CachedAssetType.audio, oldFile.path);
    final lyricsEntry = cacheEntryFixture('chant', CachedAssetType.lyrics, '${directory.path}/lyrics.ass', version: 2);
    await File(lyricsEntry.localFilePath).writeAsString('abc');
    final repository = MockCacheRepository();
    final storage = MockStorage();
    final task = FakeDownloadTask();
    addTearDown(task.events.close);
    registerFallbackValue(oldEntry);
    final writes = <ChantCacheEntity>[];
    when(() => repository.ensureCacheDirectories()).thenAnswer((_) async {});
    when(() => repository.readEntry('chant', CachedAssetType.audio)).thenAnswer((_) async => oldEntry);
    when(() => repository.readEntry('chant', CachedAssetType.lyrics)).thenAnswer((_) async => lyricsEntry);
    when(() => repository.upsertEntry(any())).thenAnswer((invocation) async {
      writes.add(invocation.positionalArguments.single as ChantCacheEntity);
    });
    when(
      () => storage.downloadFile(
        storagePath: any(named: 'storagePath'),
        destinationPath: any(named: 'destinationPath'),
      ),
    ).thenAnswer((invocation) async {
      final path = invocation.namedArguments[#destinationPath] as String;
      await File(path).writeAsString('abc');
      return task;
    });

    final fileSystem = ChantCacheFileSystem(documentsDirectoryProvider: () async => directory);
    final useCase = CacheChantsUseCase(
      chantCacheRepo: repository,
      chantCacheValidator: ChantCacheValidator(chantCacheRepo: repository, fileAccess: fileSystem),
      chantAssetDownloader: ChantAssetDownloader(
        chantCacheRepo: repository,
        chantCacheFileSystem: fileSystem,
        storageDataProvider: storage,
      ),
      localResourceResolver: ChantLocalResourceResolver(chantCacheFileSystem: fileSystem),
    );

    final progress = useCase.execute(['chant'], [chant]).toList();
    await task.listening.future;
    task.succeed();
    final events = await progress;

    expect(await oldFile.exists(), isFalse);
    final audioWrites = writes.where((entry) => entry.assetType == CachedAssetType.audio).toList();
    expect(audioWrites, hasLength(2));
    expect(audioWrites.first.failureCount, 3);
    expect(audioWrites.first.createdAtEpochMs, 42);
    expect(audioWrites.first.downloadState, CacheDownloadState.downloading);
    expect(audioWrites.last.downloadState, CacheDownloadState.complete);
    expect(audioWrites.last.isValid, isTrue);
    expect(events.last.progress, 1);
    expect(events.last.results.single.localResources.audioLocalPath, audioWrites.last.localFilePath);
  });

  test('validation failure is propagated and marks the cache entry as failed', () async {
    final directory = await Directory.systemTemp.createTemp('chant-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final repository = MockCacheRepository();
    final storage = MockStorage();
    final task = FakeDownloadTask();
    addTearDown(task.events.close);
    final chant = chantFixture('chant');
    late String destinationPath;
    registerFallbackValue(cacheEntryFixture('chant', CachedAssetType.audio, '/old'));
    registerFallbackValue(CachedAssetType.audio);
    registerFallbackValue(CacheDownloadState.failed);
    when(() => repository.upsertEntry(any())).thenAnswer((_) async {});
    when(
      () => repository.markState(
        contentId: any(named: 'contentId'),
        assetType: any(named: 'assetType'),
        state: any(named: 'state'),
        lastError: any(named: 'lastError'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => storage.downloadFile(
        storagePath: any(named: 'storagePath'),
        destinationPath: any(named: 'destinationPath'),
      ),
    ).thenAnswer((invocation) async {
      destinationPath = invocation.namedArguments[#destinationPath] as String;
      await File(destinationPath).writeAsString('bad');
      return task;
    });
    final downloader = ChantAssetDownloader(
      chantCacheRepo: repository,
      chantCacheFileSystem: ChantCacheFileSystem(documentsDirectoryProvider: () async => directory),
      storageDataProvider: storage,
    );
    final progress = downloader.download([
      CacheValidationResultEntity(chant: chant, isAudioCacheValid: false, isLyricsCacheValid: true),
    ]).toList();
    await task.listening.future;
    task.succeed();

    await expectLater(progress, throwsA(isA<FileSystemException>()));
    expect(await File(destinationPath).exists(), isFalse);
    verify(
      () => repository.markState(
        contentId: 'chant',
        assetType: CachedAssetType.audio,
        state: CacheDownloadState.failed,
        lastError: any(named: 'lastError', that: contains('hash mismatch')),
      ),
    ).called(1);
  });

  test('a failed download cancels other transfers and records both failures', () async {
    final directory = await Directory.systemTemp.createTemp('chant-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final repository = MockCacheRepository();
    final storage = MockStorage();
    final audio = FakeDownloadTask();
    final lyrics = FakeDownloadTask();
    addTearDown(audio.events.close);
    addTearDown(lyrics.events.close);
    registerFallbackValue(cacheEntryFixture('chant', CachedAssetType.audio, '/old'));
    registerFallbackValue(CachedAssetType.audio);
    registerFallbackValue(CacheDownloadState.failed);
    when(() => repository.upsertEntry(any())).thenAnswer((_) async {});
    when(
      () => repository.markState(
        contentId: any(named: 'contentId'),
        assetType: any(named: 'assetType'),
        state: any(named: 'state'),
        lastError: any(named: 'lastError'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => storage.downloadFile(
        storagePath: any(named: 'storagePath'),
        destinationPath: any(named: 'destinationPath'),
      ),
    ).thenAnswer((invocation) async {
      final path = invocation.namedArguments[#destinationPath] as String;
      return path.endsWith('.mp3') ? audio : lyrics;
    });
    final downloader = ChantAssetDownloader(
      chantCacheRepo: repository,
      chantCacheFileSystem: ChantCacheFileSystem(documentsDirectoryProvider: () async => directory),
      storageDataProvider: storage,
    );
    final progress = downloader.download([
      CacheValidationResultEntity(chant: chantFixture('chant'), isAudioCacheValid: false, isLyricsCacheValid: false),
    ]).toList();
    final assertion = expectLater(progress, throwsA(isA<StateError>()));
    await Future.wait([audio.listening.future, lyrics.listening.future]);
    audio.currentSnapshot.state = TaskState.error;
    audio.completion.completeError(StateError('download failed'));
    await assertion;

    expect(lyrics.currentSnapshot.state, TaskState.canceled);
    verify(
      () => repository.markState(
        contentId: 'chant',
        assetType: CachedAssetType.audio,
        state: CacheDownloadState.failed,
        lastError: any(named: 'lastError'),
      ),
    ).called(1);
    verify(
      () => repository.markState(
        contentId: 'chant',
        assetType: CachedAssetType.lyrics,
        state: CacheDownloadState.failed,
        lastError: any(named: 'lastError'),
      ),
    ).called(1);
  });

  test('a failure starting a later transfer cancels and records the earlier one', () async {
    final directory = await Directory.systemTemp.createTemp('chant-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final repository = MockCacheRepository();
    final storage = MockStorage();
    final audio = FakeDownloadTask();
    addTearDown(audio.events.close);
    registerFallbackValue(cacheEntryFixture('chant', CachedAssetType.audio, '/old'));
    registerFallbackValue(CachedAssetType.audio);
    registerFallbackValue(CacheDownloadState.failed);
    when(() => repository.upsertEntry(any())).thenAnswer((_) async {});
    when(
      () => repository.markState(
        contentId: any(named: 'contentId'),
        assetType: any(named: 'assetType'),
        state: any(named: 'state'),
        lastError: any(named: 'lastError'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => storage.downloadFile(
        storagePath: any(named: 'storagePath'),
        destinationPath: any(named: 'destinationPath'),
      ),
    ).thenAnswer((invocation) async {
      final path = invocation.namedArguments[#destinationPath] as String;
      if (path.endsWith('.ass')) throw StateError('could not start lyrics');
      return audio;
    });
    final downloader = ChantAssetDownloader(
      chantCacheRepo: repository,
      chantCacheFileSystem: ChantCacheFileSystem(documentsDirectoryProvider: () async => directory),
      storageDataProvider: storage,
    );

    await expectLater(
      downloader.download([
        CacheValidationResultEntity(chant: chantFixture('chant'), isAudioCacheValid: false, isLyricsCacheValid: false),
      ]),
      emitsError(isA<StateError>()),
    );

    expect(audio.currentSnapshot.state, TaskState.canceled);
    verify(
      () => repository.markState(
        contentId: 'chant',
        assetType: CachedAssetType.audio,
        state: CacheDownloadState.failed,
        lastError: any(named: 'lastError'),
      ),
    ).called(1);
    verify(
      () => repository.markState(
        contentId: 'chant',
        assetType: CachedAssetType.lyrics,
        state: CacheDownloadState.failed,
        lastError: any(named: 'lastError'),
      ),
    ).called(1);
  });

  test('cancelling the stream cancels the transfer and removes the partial file', () async {
    final directory = await Directory.systemTemp.createTemp('chant-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final repository = MockCacheRepository();
    final storage = MockStorage();
    final task = FakeDownloadTask();
    addTearDown(task.events.close);
    registerFallbackValue(cacheEntryFixture('chant', CachedAssetType.audio, '/old'));
    registerFallbackValue(CachedAssetType.audio);
    registerFallbackValue(CacheDownloadState.failed);
    when(() => repository.upsertEntry(any())).thenAnswer((_) async {});
    when(
      () => repository.markState(
        contentId: any(named: 'contentId'),
        assetType: any(named: 'assetType'),
        state: any(named: 'state'),
        lastError: any(named: 'lastError'),
      ),
    ).thenAnswer((_) async {});
    late String path;
    when(
      () => storage.downloadFile(
        storagePath: any(named: 'storagePath'),
        destinationPath: any(named: 'destinationPath'),
      ),
    ).thenAnswer((invocation) async {
      path = invocation.namedArguments[#destinationPath] as String;
      await File(path).writeAsString('partial');
      return task;
    });
    final downloader = ChantAssetDownloader(
      chantCacheRepo: repository,
      chantCacheFileSystem: ChantCacheFileSystem(documentsDirectoryProvider: () async => directory),
      storageDataProvider: storage,
    );
    final subscription = downloader
        .download([
          CacheValidationResultEntity(chant: chantFixture('chant'), isAudioCacheValid: false, isLyricsCacheValid: true),
        ])
        .listen((_) {});
    await task.listening.future;
    await subscription.cancel();

    expect(task.currentSnapshot.state, TaskState.canceled);
    expect(await File(path).exists(), isFalse);
    verify(
      () => repository.markState(
        contentId: 'chant',
        assetType: CachedAssetType.audio,
        state: CacheDownloadState.failed,
        lastError: any(named: 'lastError'),
      ),
    ).called(1);
  });
}
