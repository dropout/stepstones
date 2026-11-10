import 'dart:async';

import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
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

class MockPlaybackStateChangeUseCase extends Mock implements PlaybackStateChangeUseCase {}

void main() {
  late MockChantingAudioService audioService;
  late MockSessionNavigator sessionNavigator;
  late MockCrashlyticsService crashlyticsService;
  late StreamController<String> chantCompleted;
  late StreamController<void> playlistCompleted;

  setUpAll(() {
    registerFallbackValue(SessionType.chanting);
    registerFallbackValue(NavigationType.go);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    audioService = MockChantingAudioService();
    sessionNavigator = MockSessionNavigator();
    crashlyticsService = MockCrashlyticsService();
    chantCompleted = StreamController<String>.broadcast();
    playlistCompleted = StreamController<void>.broadcast();

    when(() => audioService.playbackState).thenReturn(ChantPlaybackStateEntity(updateTime: DateTime(2026)));
    when(() => audioService.playbackStateStream).thenAnswer((_) => const Stream.empty());
    when(() => audioService.mediaItemStream).thenAnswer((_) => const Stream.empty());
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
  });

  ChantingCubit buildCubit() => ChantingCubit(
    sessionNavigator: sessionNavigator,
    chantingSettings: const ChantingSettings(),
    audioService: audioService,
    crashlyticsService: crashlyticsService,
    startChantingUseCase: MockStartChantingUseCase(),
    loadLyricsUseCase: MockLoadLyricsUseCase(),
    playbackStateChangeUseCase: MockPlaybackStateChangeUseCase(),
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
