import 'dart:convert';

import 'package:chanting/src/audio/so_chanting_audio_handler.dart';
import 'package:chanting/src/data/mapper/chant_local_resources_mapper.dart';
import 'package:chanting/src/data/mapper/chant_playback_mapper.dart';
import 'package:chanting/src/domain/entity/chant_local_resources_entity.dart';
import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
import 'package:chanting/src/domain/entity/chant_track_entity.dart';
import 'package:chanting/src/domain/service/chanting_audio_service.dart';
import 'package:core/core.dart';

class DefaultChantingAudioService implements ChantingAudioService {
  final AppAudioHandler audioHandler;

  DefaultChantingAudioService(this.audioHandler) {
    audioHandler.switchToChantingAudioHandler();
  }

  @override
  Future<Duration> setup(List<ChantLocalResourcesEntity> resources) async {
    final result = await audioHandler.customAction(SoLoudChantingAudioHandlerCustomAction.setup.name, {
      'resources': jsonEncode(resources.map((resource) => resource.toApi()).toList()),
    });
    if (result is! Duration) {
      throw StateError('Chanting audio setup returned an invalid duration: $result');
    }
    return result;
  }

  @override
  Future<void> play() => audioHandler.play();
  @override
  Future<void> pause() => audioHandler.pause();
  @override
  Future<void> seek(Duration position) => audioHandler.seek(position);
  @override
  Future<void> stop() => audioHandler.stop();
  @override
  Future<void> prev() => audioHandler.skipToPrevious();
  @override
  Future<void> next() => audioHandler.skipToNext();
  @override
  ChantPlaybackStateEntity get playbackState => audioHandler.playbackState.value.toDomain();
  @override
  Stream<ChantPlaybackStateEntity> get playbackStateStream =>
      audioHandler.playbackState.map((state) => state.toDomain());
  @override
  Stream<ChantTrackEntity?> get mediaItemStream => audioHandler.mediaItem.map((item) => item?.toDomain());
  @override
  Future<Duration> get outputLatency => audioHandler.outputLatency;
  @override
  Stream<void> get audioRouteChangeStream => audioHandler.audioRouteChangeStream;
  @override
  Stream<void> get playlistCompletedStream =>
      audioHandler.customEvent.where((event) => event == SoLoudChantingAudioHandlerCustomEvent.playlistCompleted);
  @override
  Stream<String> get chantCompletedStream => audioHandler.customEvent
      .where((event) => event is SoLoudChantingTrackCompletedEvent)
      .map((event) => (event as SoLoudChantingTrackCompletedEvent).mediaId);
}
