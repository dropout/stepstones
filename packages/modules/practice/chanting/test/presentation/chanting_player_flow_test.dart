import 'dart:async';
import 'dart:io';

import 'package:chanting/chanting.dart';
import 'package:chanting/src/data/service/default_lyrics_service.dart';
import 'package:chanting/src/domain/entity/caching_progress_entity.dart';
import 'package:chanting/src/domain/entity/chant_local_resources_entity.dart';
import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
import 'package:chanting/src/domain/entity/chant_track_entity.dart';
import 'package:chanting/src/domain/repository/chant_repository.dart';
import 'package:chanting/src/domain/service/chanting_app_port.dart';
import 'package:chanting/src/domain/service/chanting_audio_service.dart';
import 'package:chanting/src/domain/usecase/cache_chants_use_case.dart';
import 'package:chanting/src/domain/usecase/complete_chanting_use_case.dart';
import 'package:chanting/src/domain/usecase/load_lyrics_use_case.dart';
import 'package:chanting/src/domain/usecase/playback_state_change_use_case.dart';
import 'package:chanting/src/domain/usecase/start_chanting_use_case.dart';
import 'package:chanting/src/presentation/viewmodel/chanting_cubit.dart';
import 'package:clock/clock.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/cache_fixtures.dart';

class MockChantRepository extends Mock implements ChantRepository {}

class MockCacheChantsUseCase extends Mock implements CacheChantsUseCase {}

class MockChantingAudioService extends Mock implements ChantingAudioService {}

class MockChantingAppPort extends Mock implements ChantingAppPort {}

class MockSessionNavigator extends Mock implements SessionNavigator {}

const lyrics =
    '[Events]\n'
    'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\n'
    r'Dialogue: 0,0:00:01.00,0:00:02.00,Default,,0,0,0,,{\k50}hello';

void main() {
  setUpAll(() {
    registerFallbackValue(SessionType.chanting);
    registerFallbackValue(NavigationType.go);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DateTime(2026));
  });

  test('prepares resources, loads lyrics, tracks playback and completes a session', () async {
    final directory = await Directory.systemTemp.createTemp('chanting-flow-test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/lyrics.ass');
    await file.writeAsString(lyrics);
    final chant = chantFixture('chant');
    final resource = ChantLocalResourcesEntity(
      chant: chant,
      audioLocalPath: '${directory.path}/audio.mp3',
      lyricsLocalPath: file.path,
      audioVersion: 2,
      lyricsVersion: 2,
    );
    final progress = CachingProgressEntity(progress: 1, results: [(chant: chant, localResources: resource)]);
    final repository = MockChantRepository();
    final cache = MockCacheChantsUseCase();
    final audio = MockChantingAudioService();
    final app = MockChantingAppPort();
    final navigator = MockSessionNavigator();
    final crashlytics = MockCrashlyticsService();
    final media = StreamController<ChantTrackEntity?>.broadcast(sync: true);
    final playback = StreamController<ChantPlaybackStateEntity>.broadcast(sync: true);
    final chantCompleted = StreamController<String>.broadcast(sync: true);
    final playlistCompleted = StreamController<void>.broadcast(sync: true);
    addTearDown(() async {
      await media.close();
      await playback.close();
      await chantCompleted.close();
      await playlistCompleted.close();
    });

    final baseTime = DateTime.utc(2025);
    final completedAt = DateTime.utc(2026, 12);
    when(() => audio.playbackState).thenReturn(ChantPlaybackStateEntity(updateTime: baseTime));
    when(() => audio.playbackStateStream).thenAnswer((_) => playback.stream);
    when(() => audio.mediaItemStream).thenAnswer((_) => media.stream);
    when(() => audio.audioRouteChangeStream).thenAnswer((_) => const Stream.empty());
    when(() => audio.chantCompletedStream).thenAnswer((_) => chantCompleted.stream);
    when(() => audio.playlistCompletedStream).thenAnswer((_) => playlistCompleted.stream);
    when(() => audio.outputLatency).thenAnswer((_) async => Duration.zero);
    when(() => audio.stop()).thenAnswer((_) async {});
    when(() => audio.play()).thenAnswer((_) async {});
    when(() => audio.setup([resource])).thenAnswer((_) async {
      media.add(const ChantTrackEntity(id: 'chant', title: 'chant', duration: Duration(minutes: 1)));
      return const Duration(minutes: 1);
    });
    when(() => repository.queryAll()).thenAnswer((_) async => [chant]);
    when(() => cache.execute(['chant'], [chant])).thenAnswer((_) => Stream.value(progress));
    when(() => app.getAuthSession()).thenAnswer((_) async => (userId: null, isAuthenticated: false));
    when(
      () => navigator.navigateToSessionCompletedScreen(
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        duration: any(named: 'duration'),
        sessionType: any(named: 'sessionType'),
        completedChantIds: any(named: 'completedChantIds'),
        navigationType: any(named: 'navigationType'),
      ),
    ).thenAnswer((_) async {});
    final start = StartChantingUseCase(
      chantRepo: repository,
      cacheChantsUseCase: cache,
      chantingAudioService: audio,
      chantingAppPort: app,
    );
    final cubit = withClock(
      Clock.fixed(completedAt),
      () => ChantingCubit(
        sessionNavigator: navigator,
        chantingSettings: const ChantingSettings(
          selectedChants: [
            ChantPlaylistItem(
              id: 'item',
              chantId: 'chant',
              name: 'chant',
              blurHash: '',
              order: 0,
              duration: Duration(minutes: 1),
            ),
          ],
        ),
        audioService: audio,
        crashlyticsService: crashlytics,
        startChantingUseCase: start,
        loadLyricsUseCase: LoadLyricsUseCase(lyricsService: DefaultLyricsService()),
        playbackStateChangeUseCase: PlaybackStateChangeUseCase(),
        completeChantingUseCase: CompleteChantingUseCase(),
      ),
    );
    addTearDown(cubit.close);

    await cubit.start();
    await pumpEventQueue();
    expect(cubit.state.loadingState, ProcessingState.completed);
    expect(cubit.state.chantResources, [resource]);
    expect(cubit.state.mediaItem?.id, 'chant');
    expect(cubit.state.lyricsLoadingState, ProcessingState.completed);
    expect(cubit.state.lyricsDocument?.lines.single.text, 'hello');
    final startedAt = cubit.state.startTime;
    expect(startedAt, isNotNull);

    playback.add(ChantPlaybackStateEntity(playing: true, updateTime: baseTime));
    playback.add(
      ChantPlaybackStateEntity(
        playing: true,
        updateTime: baseTime.add(const Duration(seconds: 5)),
        updatePosition: const Duration(milliseconds: 900),
      ),
    );
    expect(cubit.state.elapsedSessionTime, const Duration(seconds: 5));
    chantCompleted.add('chant');
    playlistCompleted.add(null);
    await pumpEventQueue();

    expect(cubit.state.completedChantIds, ['chant']);
    expect(cubit.state.endTime, completedAt);
    verify(
      () => navigator.navigateToSessionCompletedScreen(
        startTime: startedAt!,
        endTime: completedAt,
        duration: const Duration(seconds: 5),
        sessionType: SessionType.chanting,
        completedChantIds: ['chant'],
        navigationType: NavigationType.go,
      ),
    ).called(1);
    verifyInOrder([
      () => audio.stop(),
      () => repository.queryAll(),
      () => cache.execute(['chant'], [chant]),
      () => audio.setup([resource]),
      () => audio.play(),
    ]);
    verifyNever(
      () => crashlytics.recordError(
        exception: any(named: 'exception'),
        stackTrace: any(named: 'stackTrace'),
        reason: any(named: 'reason'),
      ),
    );
  });
}
