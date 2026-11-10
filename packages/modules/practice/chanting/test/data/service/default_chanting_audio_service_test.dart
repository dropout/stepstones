import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:chanting/src/audio/so_chanting_audio_handler.dart';
import 'package:chanting/src/data/service/default_chanting_audio_service.dart';
import 'package:chanting/src/data/mapper/chant_playback_mapper.dart';
import 'package:chanting/src/domain/entity/chant_local_resources_entity.dart';
import 'package:chanting/src/domain/entity/chant_playback_state_entity.dart';
import 'package:chanting/src/public/model/chant_local_resources.dart';
import 'package:clock/clock.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cache_fixtures.dart';

class TestAudioHandler extends BaseAudioHandler implements AppAudioHandler {
  int switches = 0;
  final calls = <String>[];
  Map<String, dynamic>? setupExtras;
  Object? setupResult = const Duration(seconds: 30);
  Object? setupError;
  Stream<void> routes = const Stream.empty();

  @override
  void switchToChantingAudioHandler() => switches++;
  @override
  void switchToTimerAudioHandler() {}
  @override
  Future<Duration> get outputLatency async => const Duration(milliseconds: 80);
  @override
  Stream<void> get audioRouteChangeStream => routes;
  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    calls.add(name);
    setupExtras = extras;
    if (setupError case final error?) throw error;
    return setupResult;
  }

  @override
  Future<void> play() async => calls.add('play');
  @override
  Future<void> pause() async => calls.add('pause');
  @override
  Future<void> stop() async => calls.add('stop');
  @override
  Future<void> seek(Duration position) async => calls.add('seek:${position.inSeconds}');
  @override
  Future<void> skipToNext() async => calls.add('next');
  @override
  Future<void> skipToPrevious() async => calls.add('prev');
}

void main() {
  test('switches handler, maps setup resources and delegates controls', () async {
    final handler = TestAudioHandler();
    final service = DefaultChantingAudioService(handler);
    final chant = chantFixture('chant');
    final resource = ChantLocalResourcesEntity(
      chant: chant,
      audioLocalPath: '/audio',
      lyricsLocalPath: '/lyrics',
      audioVersion: 2,
      lyricsVersion: 2,
      usedStaleCache: true,
    );

    expect(await service.setup([resource]), const Duration(seconds: 30));
    final json = jsonDecode(handler.setupExtras!['resources'] as String) as List<dynamic>;
    final decoded = ChantLocalResources.fromJson(json.single as Map<String, dynamic>);
    expect(decoded.chant.id, chant.id);
    expect(decoded.audioLocalPath, '/audio');
    expect(decoded.usedStaleCache, isTrue);
    await service.play();
    await service.pause();
    await service.seek(const Duration(seconds: 4));
    await service.prev();
    await service.next();
    await service.stop();
    expect(handler.switches, 1);
    expect(handler.calls, ['setup', 'play', 'pause', 'seek:4', 'prev', 'next', 'stop']);
    expect(await service.outputLatency, const Duration(milliseconds: 80));
  });

  test('rejects invalid setup results', () async {
    final handler = TestAudioHandler()..setupResult = null;
    final service = DefaultChantingAudioService(handler);
    await expectLater(service.setup([]), throwsStateError);
  });

  test('propagates handler errors and route changes', () async {
    final error = StateError('audio setup failed');
    final handler = TestAudioHandler()
      ..setupError = error
      ..routes = Stream.value(null);
    final service = DefaultChantingAudioService(handler);
    await expectLater(service.setup([]), throwsA(same(error)));
    await expectLater(service.audioRouteChangeStream, emitsInOrder([null, emitsDone]));
  });

  test('maps state without losing interpolated position or timing', () {
    final time = DateTime.utc(2025, 1, 1);
    withClock(Clock.fixed(time.add(const Duration(seconds: 3))), () {
      final handler = TestAudioHandler();
      final original = PlaybackState(
        playing: true,
        processingState: AudioProcessingState.ready,
        updateTime: time,
        updatePosition: const Duration(seconds: 4),
        speed: 1.5,
        queueIndex: 2,
      );
      handler.playbackState.add(original);
      final mapped = DefaultChantingAudioService(handler).playbackState;
      expect(mapped.position, original.position);
      expect(mapped.position, const Duration(milliseconds: 8500));
      expect(mapped.updateTime, time);
      expect(mapped.queueIndex, 2);
      expect(mapped.processingState, ChantPlaybackProcessingState.ready);
    });
  });

  test('maps every processing state and preserves position behavior when not ready or paused', () {
    final time = DateTime.utc(2025, 1, 1);
    withClock(Clock.fixed(time.add(const Duration(seconds: 3))), () {
      for (final state in AudioProcessingState.values) {
        for (final playing in [true, false]) {
          final original = PlaybackState(
            playing: playing,
            processingState: state,
            updateTime: time,
            updatePosition: const Duration(seconds: 4),
          );
          final mapped = original.toDomain();
          expect(mapped.processingState.name, state.name);
          expect(mapped.position, original.position);
        }
      }
    });
  });

  test('maps state, media and completion event streams', () async {
    final handler = TestAudioHandler();
    final service = DefaultChantingAudioService(handler);
    final playback = service.playbackStateStream.firstWhere((state) => state.playing);
    final track = service.mediaItemStream.firstWhere((item) => item != null);
    final completed = service.chantCompletedStream.first;
    final playlist = service.playlistCompletedStream.first;
    handler.playbackState.add(PlaybackState(playing: true, processingState: AudioProcessingState.buffering));
    handler.mediaItem.add(const MediaItem(id: 'chant', title: 'Title', duration: Duration(seconds: 12)));
    handler.customEvent.add(const SoLoudChantingTrackCompletedEvent('chant'));
    handler.customEvent.add(SoLoudChantingAudioHandlerCustomEvent.playlistCompleted);

    expect((await playback).processingState, ChantPlaybackProcessingState.buffering);
    expect((await track)?.id, 'chant');
    expect((await track)?.title, 'Title');
    expect((await track)?.duration, const Duration(seconds: 12));
    expect(await completed, 'chant');
    await playlist;
  });
}
