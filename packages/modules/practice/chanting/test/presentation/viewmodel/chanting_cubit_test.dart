import 'dart:async';

import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
import 'package:chanting/src/domain/entity/chant_track_entity.dart';
import 'package:chanting/src/domain/entity/chanting_state_entity.dart';
import 'package:chanting/src/domain/entity/lyrics_document_entity.dart';
import 'package:chanting/src/domain/entity/lyrics_line_entity.dart';
import 'package:chanting/src/chanting_module.dart';
import 'package:chanting/src/domain/service/chanting_audio_service.dart';
import 'package:chanting/src/domain/usecase/complete_chanting_use_case.dart';
import 'package:chanting/src/domain/usecase/load_lyrics_use_case.dart';
import 'package:chanting/src/domain/usecase/playback_state_change_use_case.dart';
import 'package:chanting/src/domain/usecase/start_chanting_use_case.dart';
import 'package:chanting/src/presentation/viewmodel/chanting_cubit.dart';
import 'package:clock/clock.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChantingAudioService extends Mock implements ChantingAudioService {}

class MockSessionNavigator extends Mock implements SessionNavigator {}

class MockStartChantingUseCase extends Mock implements StartChantingUseCase {}

class MockLoadLyricsUseCase extends Mock implements LoadLyricsUseCase {}

void main() {
  late MockChantingAudioService audioService;
  late MockSessionNavigator sessionNavigator;
  late MockCrashlyticsService crashlyticsService;
  late StreamController<String> chantCompleted;
  late StreamController<void> playlistCompleted;
  late StreamController<ChantTrackEntity?> mediaItems;
  late StreamController<ChantPlaybackStateEntity> playbackStates;
  late MockLoadLyricsUseCase loadLyricsUseCase;
  late MockStartChantingUseCase startChantingUseCase;

  setUpAll(() {
    registerFallbackValue(SessionType.chanting);
    registerFallbackValue(NavigationType.go);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(ChantingStateEntity(playbackState: ChantPlaybackStateEntity(updateTime: DateTime(2026))));
  });

  setUp(() {
    audioService = MockChantingAudioService();
    sessionNavigator = MockSessionNavigator();
    crashlyticsService = MockCrashlyticsService();
    chantCompleted = StreamController<String>.broadcast();
    playlistCompleted = StreamController<void>.broadcast();
    mediaItems = StreamController<ChantTrackEntity?>.broadcast(sync: true);
    playbackStates = StreamController<ChantPlaybackStateEntity>.broadcast(sync: true);
    loadLyricsUseCase = MockLoadLyricsUseCase();
    startChantingUseCase = MockStartChantingUseCase();

    when(() => audioService.playbackState).thenReturn(ChantPlaybackStateEntity(updateTime: DateTime(2026)));
    when(() => audioService.playbackStateStream).thenAnswer((_) => playbackStates.stream);
    when(() => audioService.mediaItemStream).thenAnswer((_) => mediaItems.stream);
    when(() => audioService.audioRouteChangeStream).thenAnswer((_) => const Stream.empty());
    when(() => audioService.chantCompletedStream).thenAnswer((_) => chantCompleted.stream);
    when(() => audioService.playlistCompletedStream).thenAnswer((_) => playlistCompleted.stream);
    when(() => audioService.outputLatency).thenAnswer((_) async => Duration.zero);
    when(() => audioService.play()).thenAnswer((_) async {});
    when(() => audioService.pause()).thenAnswer((_) async {});
    when(() => audioService.stop()).thenAnswer((_) async {});
    when(
      () => sessionNavigator.navigateToSessionCompletedScreen(
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        duration: any(named: 'duration'),
        sessionType: any(named: 'sessionType'),
        completedChantIds: any(named: 'completedChantIds'),
        navigationType: any(named: 'navigationType'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await chantCompleted.close();
    await playlistCompleted.close();
    await mediaItems.close();
    await playbackStates.close();
  });

  ChantingCubit buildCubit({ChantingSettings settings = const ChantingSettings()}) => ChantingCubit(
    sessionNavigator: sessionNavigator,
    chantingSettings: settings,
    audioService: audioService,
    crashlyticsService: crashlyticsService,
    startChantingUseCase: startChantingUseCase,
    loadLyricsUseCase: loadLyricsUseCase,
    playbackStateChangeUseCase: PlaybackStateChangeUseCase(),
    completeChantingUseCase: CompleteChantingUseCase(),
  );

  void verifyNavigatedTimes(int times) => verify(
    () => sessionNavigator.navigateToSessionCompletedScreen(
      startTime: any(named: 'startTime'),
      endTime: any(named: 'endTime'),
      duration: any(named: 'duration'),
      sessionType: any(named: 'sessionType'),
      completedChantIds: any(named: 'completedChantIds'),
      navigationType: any(named: 'navigationType'),
    ),
  ).called(times);

  test('preserves ordered playlist entries and duplicate chant ids on startup', () async {
    const settings = ChantingSettings(
      selectedChants: [
        ChantPlaylistItem(
          id: 'one',
          chantId: 'chant',
          name: 'First',
          blurHash: 'a',
          order: 2,
          duration: Duration(seconds: 10),
        ),
        ChantPlaylistItem(
          id: 'two',
          chantId: 'chant',
          name: 'Second',
          blurHash: 'b',
          order: 3,
          duration: Duration(seconds: 20),
        ),
      ],
    );
    when(() => startChantingUseCase.execute(['chant', 'chant'])).thenAnswer((_) => const Stream.empty());
    final cubit = buildCubit(settings: settings);
    expect(cubit.state.playlist.map((item) => item.id), ['one', 'two']);
    expect(cubit.state.playlist.map((item) => item.name), ['First', 'Second']);
    expect(cubit.state.sessionDuration, const Duration(seconds: 30));

    await cubit.start();
    verify(() => startChantingUseCase.execute(['chant', 'chant'])).called(1);
    expect(cubit.state.loadingState, ProcessingState.completed);
    await cubit.close();
  });

  test('reports startup errors and does not play', () async {
    final error = StateError('setup failed');
    final stackTrace = StackTrace.fromString('setup failure stack');
    when(() => startChantingUseCase.execute([])).thenAnswer((_) => Stream.error(error, stackTrace));
    final cubit = buildCubit();

    await cubit.start();

    expect(cubit.state.loadingState, ProcessingState.error);
    expect(cubit.state.startTime, isNull);
    verifyNever(() => audioService.play());
    verify(() => audioService.stop()).called(1);
    verify(
      () => crashlyticsService.recordError(
        exception: error,
        stackTrace: stackTrace,
        reason: 'Error setting up chants: $error',
      ),
    ).called(1);
    await cubit.close();
  });

  group('lyrics loading', () {
    const trackA = ChantTrackEntity(id: 'a', title: 'A');
    const trackB = ChantTrackEntity(id: 'b', title: 'B');
    const lyricsA = LyricsDocumentEntity(lines: []);
    const lyricsB = LyricsDocumentEntity(
      lines: [
        LyricsLineEntity(text: 'first', start: Duration.zero, end: Duration(seconds: 1), words: []),
        LyricsLineEntity(text: 'second', start: Duration(seconds: 1), end: Duration(seconds: 10), words: []),
      ],
    );

    test('ignores a stale result and synchronizes the current lyrics to playback', () async {
      final a = Completer<LyricsDocumentEntity>();
      final b = Completer<LyricsDocumentEntity>();
      when(() => loadLyricsUseCase.execute('a', any())).thenAnswer((_) => a.future);
      when(() => loadLyricsUseCase.execute('b', any())).thenAnswer((_) => b.future);
      final cubit = buildCubit();
      mediaItems.add(trackA);
      mediaItems.add(trackB);
      playbackStates.add(
        ChantPlaybackStateEntity(updateTime: DateTime(2026), updatePosition: const Duration(seconds: 2)),
      );
      b.complete(lyricsB);
      await pumpEventQueue();
      expect(cubit.state.mediaItem, trackB);
      expect(cubit.state.lyricsDocument, lyricsB);
      expect(cubit.state.activeLineIndex, 1);
      a.complete(lyricsA);
      await pumpEventQueue();
      expect(cubit.state.mediaItem, trackB);
      expect(cubit.state.lyricsDocument, lyricsB);
      expect(cubit.state.lyricsLoadingState, ProcessingState.completed);
      await cubit.close();
    });

    test('clears previous lyrics and ignores an earlier request for the same track', () async {
      final first = Completer<LyricsDocumentEntity>();
      final second = Completer<LyricsDocumentEntity>();
      var requests = 0;
      when(() => loadLyricsUseCase.execute('a', any()))
          .thenAnswer((_) => ++requests == 1 ? first.future : second.future);
      final cubit = buildCubit();
      mediaItems.add(trackA);
      mediaItems.add(trackA);
      first.complete(lyricsA);
      await pumpEventQueue();
      expect(cubit.state.lyricsDocument, isNull);
      expect(cubit.state.lyricsLoadingState, ProcessingState.processing);
      second.complete(lyricsB);
      await pumpEventQueue();
      expect(cubit.state.lyricsDocument, lyricsB);
      mediaItems.add(trackA);
      expect(cubit.state.lyricsDocument, isNull);
      expect(cubit.state.activeLineIndex, 0);
      await pumpEventQueue();
      await cubit.close();
    });

    test('logs stale failures without replacing the current lyrics state', () async {
      final a = Completer<LyricsDocumentEntity>();
      final b = Completer<LyricsDocumentEntity>();
      final error = StateError('failed');
      when(() => loadLyricsUseCase.execute('a', any())).thenAnswer((_) => a.future);
      when(() => loadLyricsUseCase.execute('b', any())).thenAnswer((_) => b.future);
      final cubit = buildCubit();
      mediaItems.add(trackA);
      mediaItems.add(trackB);
      b.complete(lyricsB);
      await pumpEventQueue();
      a.completeError(error);
      await pumpEventQueue();
      expect(cubit.state.lyricsDocument, lyricsB);
      expect(cubit.state.lyricsLoadingState, ProcessingState.completed);
      verify(
        () => crashlyticsService.recordError(
          exception: error,
          stackTrace: any(named: 'stackTrace'),
          reason: 'Error loading lyrics for chant a',
        ),
      ).called(1);
      await cubit.close();
    });

    test('reports a current failure and invalidates pending requests on stop', () async {
      final a = Completer<LyricsDocumentEntity>();
      final b = Completer<LyricsDocumentEntity>();
      when(() => loadLyricsUseCase.execute('a', any())).thenAnswer((_) => a.future);
      when(() => loadLyricsUseCase.execute('b', any())).thenAnswer((_) => b.future);
      final cubit = buildCubit();
      mediaItems.add(trackA);
      a.completeError(StateError('failed'));
      await pumpEventQueue();
      expect(cubit.state.lyricsLoadingState, ProcessingState.error);
      mediaItems.add(trackB);
      mediaItems.add(null);
      b.complete(lyricsB);
      await pumpEventQueue();
      expect(cubit.state.mediaItem, isNull);
      expect(cubit.state.lyricsDocument, isNull);
      expect(cubit.state.lyricsLoadingState, ProcessingState.processing);
      await cubit.close();
    });

    test('logs failures arriving after close without emitting', () async {
      final a = Completer<LyricsDocumentEntity>();
      final error = StateError('failed after close');
      when(() => loadLyricsUseCase.execute('a', any())).thenAnswer((_) => a.future);
      final cubit = buildCubit();
      mediaItems.add(trackA);
      await pumpEventQueue();
      await cubit.close();
      a.completeError(error);
      await pumpEventQueue();
      verify(
        () => crashlyticsService.recordError(
          exception: error,
          stackTrace: any(named: 'stackTrace'),
          reason: 'Error loading lyrics for chant a',
        ),
      ).called(1);
    });

    test('playback updates cannot restore a previous track while lyrics load', () async {
      final a = Completer<LyricsDocumentEntity>();
      final b = Completer<LyricsDocumentEntity>();
      when(() => loadLyricsUseCase.execute('a', any())).thenAnswer((_) => a.future);
      when(() => loadLyricsUseCase.execute('b', any())).thenAnswer((_) => b.future);
      final cubit = buildCubit();
      mediaItems.add(trackA);
      a.complete(lyricsA);
      await pumpEventQueue();
      playbackStates.add(ChantPlaybackStateEntity(updateTime: DateTime(2026), playing: true));
      mediaItems.add(trackB);
      await pumpEventQueue();
      expect(cubit.state.mediaItem, trackB);
      expect(cubit.state.lyricsDocument, isNull);
      expect(cubit.state.lyricsLoadingState, ProcessingState.processing);
      b.complete(lyricsB);
      await pumpEventQueue();
      expect(cubit.state.mediaItem, trackB);
      expect(cubit.state.lyricsDocument, lyricsB);
      await cubit.close();
    });
  });

  group('finishEarly', () {
    test('logs only finished chants up to the last completion', () async {
      final start = DateTime(2026, 1, 1, 10);
      final completedAt = DateTime(2026, 1, 1, 10, 5);
      // Stream callbacks run in the zone the cubit subscribed in.
      final cubit = withClock(Clock.fixed(completedAt), buildCubit);
      cubit.emit(cubit.state.copyWith(startTime: start, elapsedSessionTime: const Duration(minutes: 5)));

      chantCompleted.add('chant-a');
      await pumpEventQueue();
      cubit.emit(cubit.state.copyWith(elapsedSessionTime: const Duration(minutes: 7)));

      await cubit.finishEarly();

      verify(() => audioService.pause()).called(1);
      verify(
        () => sessionNavigator.navigateToSessionCompletedScreen(
          startTime: start,
          endTime: completedAt,
          duration: const Duration(minutes: 5),
          sessionType: SessionType.chanting,
          completedChantIds: ['chant-a'],
          navigationType: NavigationType.go,
        ),
      ).called(1);
      await cubit.close();
    });

    test('does nothing without finished chants', () async {
      final cubit = buildCubit();
      await cubit.finishEarly();
      verifyNever(
        () => sessionNavigator.navigateToSessionCompletedScreen(
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          duration: any(named: 'duration'),
          sessionType: any(named: 'sessionType'),
          completedChantIds: any(named: 'completedChantIds'),
          navigationType: any(named: 'navigationType'),
        ),
      );
      await cubit.close();
    });

    test('playlist completion after finishing early does not navigate again', () async {
      final cubit = buildCubit();
      chantCompleted.add('chant-a');
      await pumpEventQueue();

      await cubit.finishEarly();
      playlistCompleted.add(null);
      await pumpEventQueue();

      verifyNavigatedTimes(1);
      await cubit.close();
    });

    test('records error and allows retry when navigation fails', () async {
      final cubit = buildCubit();
      chantCompleted.add('chant-a');
      await pumpEventQueue();
      when(
        () => sessionNavigator.navigateToSessionCompletedScreen(
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          duration: any(named: 'duration'),
          sessionType: any(named: 'sessionType'),
          completedChantIds: any(named: 'completedChantIds'),
          navigationType: any(named: 'navigationType'),
        ),
      ).thenThrow(Exception('nav'));

      await cubit.finishEarly();

      verify(
        () => crashlyticsService.recordError(
          exception: any(named: 'exception'),
          stackTrace: any(named: 'stackTrace'),
          reason: any(named: 'reason'),
        ),
      ).called(1);
      await cubit.close();
    });
  });

  group('exit prompt', () {
    test('pauses and resumes when it was playing', () async {
      final cubit = buildCubit();
      cubit.emit(
        cubit.state.copyWith(playbackState: ChantPlaybackStateEntity(playing: true, updateTime: DateTime(2026))),
      );

      await cubit.pauseForExitPrompt();
      await cubit.resumeAfterExitPrompt();

      verify(() => audioService.pause()).called(1);
      verify(() => audioService.play()).called(1);
      await cubit.close();
    });

    test('does not resume when it was paused', () async {
      final cubit = buildCubit();

      await cubit.pauseForExitPrompt();
      await cubit.resumeAfterExitPrompt();

      verifyNever(() => audioService.pause());
      verifyNever(() => audioService.play());
      await cubit.close();
    });
  });
}
