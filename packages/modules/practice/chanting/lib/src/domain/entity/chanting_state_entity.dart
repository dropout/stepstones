import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import 'package:chanting/src/chanting_module.dart';
import 'package:chanting/src/domain/entity/caching_progress_entity.dart';
import 'package:chanting/src/domain/entity/chant_local_resources_entity.dart';
import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
import 'package:chanting/src/domain/entity/chant_track_entity.dart';
import 'package:chanting/src/domain/entity/lyrics_document_entity.dart';

part 'chanting_state_entity.freezed.dart';

@freezed
sealed class ChantingStateEntity with _$ChantingStateEntity {
  const ChantingStateEntity._();

  const factory ChantingStateEntity({
    // settings
    required ChantingSettings chantingSettings,

    // loading
    @Default(CachingProgressEntity()) CachingProgressEntity cachingProgress,

    // playback
    @Default([]) List<ChantLocalResourcesEntity> chantResources,
    required ChantPlaybackStateEntity playbackState,
    @Default(Duration.zero) Duration elapsedTime,
    @Default(ProcessingState.processing) ProcessingState loadingState,
    ChantTrackEntity? mediaItem,
    @Default(Duration.zero) Duration outputLatency,

    // lyrics
    @Default(0) int activeLineIndex,
    @Default(ProcessingState.processing) ProcessingState lyricsLoadingState,
    LyricsDocumentEntity? lyricsDocument,

    // session data
    DateTime? startTime,
    DateTime? endTime,
    @Default(Duration.zero) Duration elapsedSessionTime,
    @Default([]) List<String> completedChantIds,

    // Snapshot at the last finished chant, used when the session ends early.
    @Default(Duration.zero) Duration completedChantsElapsedTime,
    DateTime? lastChantCompletedAt,
  }) = _ChantingStateEntity;

  /// Records a finished chant together with the session time spent so far.
  ChantingStateEntity withChantCompleted(String chantId, DateTime at) => copyWith(
    completedChantIds: [...completedChantIds, chantId],
    completedChantsElapsedTime: elapsedSessionTime,
    lastChantCompletedAt: at,
  );

  /// Playback has started, so leaving should be confirmed.
  bool get isSessionStarted => loadingState == ProcessingState.completed;

  bool get hasCompletedChants => completedChantIds.isNotEmpty;

  /// Session data covering only the finished chants.
  ({DateTime startTime, DateTime endTime, Duration duration, List<String> completedChantIds})
  get finishedChantsSession {
    final endTime = lastChantCompletedAt ?? clock.now();
    return (
      startTime: startTime ?? endTime.subtract(completedChantsElapsedTime),
      endTime: endTime,
      duration: completedChantsElapsedTime,
      completedChantIds: completedChantIds,
    );
  }

  int get currentIndex => playbackState.queueIndex ?? 0;
  Duration get position => playbackState.position + Duration(milliseconds: 250);
  Duration get latencyCompensatedPosition {
    final compensated = position - outputLatency;
    return compensated.isNegative ? Duration.zero : compensated;
  }

  Duration get currentTrackDuration => mediaItem?.duration ?? Duration.zero;
  Duration get sessionDuration =>
      chantingSettings.selectedChants.fold(Duration.zero, (total, chant) => total + chant.duration);
}
