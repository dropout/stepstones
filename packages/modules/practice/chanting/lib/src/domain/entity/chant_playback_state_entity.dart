import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chant_playback_state_entity.freezed.dart';

enum ChantPlaybackProcessingState { idle, loading, buffering, ready, completed, error }

@freezed
sealed class ChantPlaybackStateEntity with _$ChantPlaybackStateEntity {
  const ChantPlaybackStateEntity._();

  const factory ChantPlaybackStateEntity({
    @Default(ChantPlaybackProcessingState.idle) ChantPlaybackProcessingState processingState,
    @Default(false) bool playing,
    @Default(Duration.zero) Duration updatePosition,
    @Default(1.0) double speed,
    required DateTime updateTime,
    int? queueIndex,
  }) = _ChantPlaybackStateEntity;

  Duration get position {
    if (playing && processingState == ChantPlaybackProcessingState.ready) {
      return Duration(
        milliseconds:
            (updatePosition.inMilliseconds +
                    speed * (clock.now().millisecondsSinceEpoch - updateTime.millisecondsSinceEpoch))
                .toInt(),
      );
    }
    return updatePosition;
  }
}
