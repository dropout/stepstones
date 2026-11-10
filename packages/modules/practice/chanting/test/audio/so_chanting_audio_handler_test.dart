import 'dart:convert';
import 'dart:io';

import 'package:chanting/src/audio/so_chanting_audio_handler.dart';
import 'package:chanting/src/audio/so_chanting_audio_resource_manager.dart';
import 'package:chanting/src/audio/so_chanting_playback_reporter.dart';
import 'package:chanting/src/audio/so_chanting_playlist_manager.dart';
import 'package:chanting/src/data/mapper/chant_local_resources_mapper.dart';
import 'package:chanting/src/domain/entity/chant_local_resources_entity.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/cache_fixtures.dart';

class MockSoLoud extends Mock implements SoLoud {
  @override
  void setInaudibleBehavior(SoundHandle handle, bool mustTick, bool kill) => throw UnimplementedError();
}

class MockAudioResourceManager extends Mock implements SoChantingAudioResourceManager {}

class MockPlaybackReporter extends Mock implements SoChantingPlaybackReporter {}

class FailingPlaylistManager extends SoChantingPlaylistManager {
  final Object error;
  final StackTrace stackTrace;

  FailingPlaylistManager(this.error, this.stackTrace);

  @override
  Future<void> setup(List<SoChantingPlaylistEntry> entries) async {
    Error.throwWithStackTrace(error, stackTrace);
  }
}

void main() {
  late MockSoLoud soloud;
  late MockPlaybackReporter reporter;

  setUp(() {
    soloud = MockSoLoud();
    reporter = MockPlaybackReporter();
    when(() => soloud.isInitialized).thenReturn(true);
    when(() => reporter.stop()).thenReturn(null);
  });

  SoLoudChantingAudioHandler handler({SoChantingPlaylistManager? playlist}) => SoLoudChantingAudioHandler(
    soloud: soloud,
    audioResourceManager: MockAudioResourceManager(),
    playlistManager: playlist ?? SoChantingPlaylistManager(),
    playbackReporter: reporter,
  );

  Map<String, dynamic> extrasFor(String path) {
    final resource = ChantLocalResourcesEntity(
      chant: chantFixture('chant'),
      audioLocalPath: path,
      lyricsLocalPath: '$path.lyrics',
      audioVersion: 2,
      lyricsVersion: 2,
    );
    return {
      'resources': jsonEncode([resource.toApi()]),
    };
  }

  const action = 'setup';

  test('valid and empty resource lists preserve setup behavior', () async {
    final directory = await Directory.systemTemp.createTemp('chant-audio-test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/chant.audio');
    await file.writeAsBytes([1]);
    final audioHandler = handler();
    addTearDown(audioHandler.close);

    expect(await audioHandler.customAction(action, extrasFor(file.path)), const Duration(minutes: 1));
    expect(audioHandler.mediaItem.value?.id, 'chant');
    expect(await audioHandler.customAction(action, {'resources': '[]'}), Duration.zero);
    expect(await audioHandler.customAction(action, {}), Duration.zero);
  });

  test('invalid payloads are argument errors without exposing extras', () async {
    final audioHandler = handler();
    addTearDown(audioHandler.close);
    for (final extras in [
      null,
      {'resources': 4},
      {'resources': 'secret malformed json'},
      {'resources': '{}'},
      {'resources': '[{}]'},
    ]) {
      await expectLater(
        audioHandler.customAction(action, extras),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('Invalid extras'), isNot(contains('secret'))),
          ),
        ),
      );
    }
  });

  test('missing audio file retains its filesystem error', () async {
    final directory = await Directory.systemTemp.createTemp('chant-audio-test');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/missing.audio';
    final audioHandler = handler();
    addTearDown(audioHandler.close);

    await expectLater(
      audioHandler.customAction(action, extrasFor(path)),
      throwsA(isA<FileSystemException>().having((error) => error.path, 'path', path)),
    );
  });

  test('playlist failure preserves the original error and stack trace', () async {
    final directory = await Directory.systemTemp.createTemp('chant-audio-test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/chant.audio');
    await file.writeAsBytes([1]);
    final error = StateError('playlist failure');
    final stackTrace = StackTrace.fromString('playlist setup stack');
    final audioHandler = handler(playlist: FailingPlaylistManager(error, stackTrace));
    addTearDown(audioHandler.close);

    try {
      await audioHandler.customAction(action, extrasFor(file.path));
      fail('Expected playlist setup to fail');
    } catch (caught, stack) {
      expect(caught, same(error));
      expect(stack.toString(), stackTrace.toString());
    }
  });
}
