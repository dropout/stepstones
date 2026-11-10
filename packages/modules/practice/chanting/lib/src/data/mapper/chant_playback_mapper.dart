import 'package:audio_service/audio_service.dart';
import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
import 'package:chanting/src/domain/entity/chant_track_entity.dart';

extension ChantPlaybackStateMapper on PlaybackState {
  ChantPlaybackStateEntity toDomain() => ChantPlaybackStateEntity(
    processingState: switch (processingState) {
      AudioProcessingState.idle => ChantPlaybackProcessingState.idle,
      AudioProcessingState.loading => ChantPlaybackProcessingState.loading,
      AudioProcessingState.buffering => ChantPlaybackProcessingState.buffering,
      AudioProcessingState.ready => ChantPlaybackProcessingState.ready,
      AudioProcessingState.completed => ChantPlaybackProcessingState.completed,
      AudioProcessingState.error => ChantPlaybackProcessingState.error,
    },
    playing: playing,
    updatePosition: updatePosition,
    speed: speed,
    updateTime: updateTime,
    queueIndex: queueIndex,
  );
}

extension ChantTrackMapper on MediaItem {
  ChantTrackEntity toDomain() => ChantTrackEntity(id: id, title: title, duration: duration);
}
