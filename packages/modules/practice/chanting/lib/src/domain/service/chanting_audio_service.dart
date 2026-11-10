import 'package:chanting/src/domain/entity/chant_local_resources_entity.dart';
import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
import 'package:chanting/src/domain/entity/chant_track_entity.dart';

abstract interface class ChantingAudioService {
  Future<Duration> setup(List<ChantLocalResourcesEntity> resources);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> prev();
  Future<void> next();

  ChantPlaybackStateEntity get playbackState;
  Stream<ChantPlaybackStateEntity> get playbackStateStream;
  Stream<ChantTrackEntity?> get mediaItemStream;
  Future<Duration> get outputLatency;
  Stream<void> get audioRouteChangeStream;
  Stream<void> get playlistCompletedStream;
  Stream<String> get chantCompletedStream;
}
