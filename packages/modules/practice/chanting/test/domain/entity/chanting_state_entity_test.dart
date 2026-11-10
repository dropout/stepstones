import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
import 'package:chanting/src/domain/entity/chanting_state_entity.dart';
import 'package:clock/clock.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ChantingStateEntity buildState({
    Duration elapsed = Duration.zero,
    DateTime? startTime,
    ProcessingState loadingState = ProcessingState.processing,
  }) => ChantingStateEntity(
    playbackState: ChantPlaybackStateEntity(updateTime: DateTime(2026)),
    elapsedSessionTime: elapsed,
    startTime: startTime,
    loadingState: loadingState,
  );

  group('withChantCompleted', () {
    test('records chant id and snapshots elapsed time', () {
      final at = DateTime(2026, 1, 1, 10, 5);
      final state = buildState(elapsed: const Duration(minutes: 5)).withChantCompleted('a', at);

      expect(state.completedChantIds, ['a']);
      expect(state.completedChantsElapsedTime, const Duration(minutes: 5));
      expect(state.lastChantCompletedAt, at);
      expect(state.hasCompletedChants, isTrue);
    });
  });

  group('finishedChantsSession', () {
    test('excludes time spent in the unfinished chant', () {
      final start = DateTime(2026, 1, 1, 10);
      final completedAt = DateTime(2026, 1, 1, 10, 5);
      final state = buildState(
        elapsed: const Duration(minutes: 5),
        startTime: start,
      ).withChantCompleted('a', completedAt).copyWith(elapsedSessionTime: const Duration(minutes: 8));

      final session = state.finishedChantsSession;

      expect(session.startTime, start);
      expect(session.endTime, completedAt);
      expect(session.duration, const Duration(minutes: 5));
      expect(session.completedChantIds, ['a']);
    });

    test('falls back to clock when no chant completed', () {
      final now = DateTime(2026, 1, 1, 12);
      final session = withClock(Clock.fixed(now), () => buildState().finishedChantsSession);

      expect(session.endTime, now);
      expect(session.duration, Duration.zero);
    });
  });

  test('isSessionStarted reflects loading state', () {
    expect(buildState().isSessionStarted, isFalse);
    expect(buildState(loadingState: ProcessingState.completed).isSessionStarted, isTrue);
  });
}
