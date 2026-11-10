import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
import 'package:chanting/src/domain/entity/chanting_state_entity.dart';
import 'package:chanting/src/domain/usecase/playback_state_change_use_case.dart';
import 'package:chanting/src/public/model/chant_playlist_item.dart';
import 'package:chanting/src/public/model/chanting_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accumulates time only across consecutive playing updates', () async {
    final time = DateTime.utc(2025);
    final initial = ChantingStateEntity(
      chantingSettings: const ChantingSettings(),
      playbackState: ChantPlaybackStateEntity(playing: true, updateTime: time),
      elapsedSessionTime: const Duration(seconds: 10),
    );
    final useCase = PlaybackStateChangeUseCase();
    final playing = await useCase.execute(
      initial,
      ChantPlaybackStateEntity(playing: true, updateTime: time.add(const Duration(seconds: 3))),
    );
    final paused = await useCase.execute(
      playing,
      ChantPlaybackStateEntity(updateTime: time.add(const Duration(seconds: 5))),
    );
    expect(playing.elapsedSessionTime, const Duration(seconds: 13));
    expect(paused.elapsedSessionTime, playing.elapsedSessionTime);
  });

  test('marks completion only at the last playlist item', () async {
    final settings = ChantingSettings(
      selectedChants: [
        const ChantPlaylistItem(id: 'a', chantId: 'a', name: 'a', blurHash: '', order: 0, duration: Duration.zero),
        const ChantPlaylistItem(id: 'b', chantId: 'b', name: 'b', blurHash: '', order: 1, duration: Duration.zero),
      ],
    );
    final time = DateTime.utc(2025);
    final initial = ChantingStateEntity(
      chantingSettings: settings,
      playbackState: ChantPlaybackStateEntity(updateTime: time),
    );
    final useCase = PlaybackStateChangeUseCase();
    final first = await useCase.execute(
      initial,
      ChantPlaybackStateEntity(
        processingState: ChantPlaybackProcessingState.completed,
        queueIndex: 0,
        updateTime: time,
      ),
    );
    final last = await useCase.execute(
      first,
      ChantPlaybackStateEntity(
        processingState: ChantPlaybackProcessingState.completed,
        queueIndex: 1,
        updateTime: time,
      ),
    );
    expect(first.endTime, isNull);
    expect(last.endTime, isNotNull);
  });
}
