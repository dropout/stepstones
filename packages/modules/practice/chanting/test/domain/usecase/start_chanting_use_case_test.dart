import 'package:chanting/src/domain/entity/caching_progress_entity.dart';
import 'package:chanting/src/domain/entity/chant_local_resources_entity.dart';
import 'package:chanting/src/domain/exception/chants_unavailable_offline_exception.dart';
import 'package:chanting/src/domain/repository/chant_repository.dart';
import 'package:chanting/src/domain/service/chanting_app_port.dart';
import 'package:chanting/src/domain/service/chanting_audio_service.dart';
import 'package:chanting/src/domain/usecase/cache_chants_use_case.dart';
import 'package:chanting/src/domain/usecase/start_chanting_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/cache_fixtures.dart';

class MockRepository extends Mock implements ChantRepository {}

class MockCache extends Mock implements CacheChantsUseCase {}

class MockAudio extends Mock implements ChantingAudioService {}

class MockAppPort extends Mock implements ChantingAppPort {}

void main() {
  test('stops, caches, sets up and plays before showing presence', () async {
    final chant = chantFixture('chant');
    final resources = ChantLocalResourcesEntity(
      chant: chant,
      audioLocalPath: '/audio',
      lyricsLocalPath: '/lyrics',
      audioVersion: 2,
      lyricsVersion: 2,
    );
    final progress = CachingProgressEntity(progress: 1, results: [(chant: chant, localResources: resources)]);
    final repository = MockRepository();
    final cache = MockCache();
    final audio = MockAudio();
    final app = MockAppPort();
    when(() => audio.stop()).thenAnswer((_) async {});
    when(() => repository.queryAll()).thenAnswer((_) async => [chant]);
    when(() => cache.execute(['chant'], [chant])).thenAnswer((_) => Stream.value(progress));
    when(() => audio.setup([resources])).thenAnswer((_) async => Duration.zero);
    when(() => audio.play()).thenAnswer((_) async {});
    when(() => app.getAuthSession()).thenAnswer((_) async => (userId: null, isAuthenticated: false));
    final useCase = StartChantingUseCase(
      chantRepo: repository,
      cacheChantsUseCase: cache,
      chantingAudioService: audio,
      chantingAppPort: app,
    );

    expect(await useCase.execute(['chant']).toList(), [progress]);
    verifyInOrder([
      () => audio.stop(),
      () => repository.queryAll(),
      () => cache.execute(['chant'], [chant]),
      () => audio.setup([resources]),
      () => audio.play(),
      () => app.getAuthSession(),
    ]);
  });

  test('does not play when audio setup fails', () async {
    final chant = chantFixture('chant');
    final resources = ChantLocalResourcesEntity(
      chant: chant,
      audioLocalPath: '/audio',
      lyricsLocalPath: '/lyrics',
      audioVersion: 2,
      lyricsVersion: 2,
    );
    final repository = MockRepository();
    final cache = MockCache();
    final audio = MockAudio();
    final app = MockAppPort();
    when(() => audio.stop()).thenAnswer((_) async {});
    when(() => repository.queryAll()).thenAnswer((_) async => [chant]);
    when(() => cache.execute(['chant'], [chant])).thenAnswer(
      (_) => Stream.value(CachingProgressEntity(progress: 1, results: [(chant: chant, localResources: resources)])),
    );
    final error = StateError('setup failed');
    when(() => audio.setup([resources])).thenThrow(error);
    final useCase = StartChantingUseCase(
      chantRepo: repository,
      cacheChantsUseCase: cache,
      chantingAudioService: audio,
      chantingAppPort: app,
    );

    await expectLater(
      useCase.execute(['chant']),
      emitsInOrder([isA<CachingProgressEntity>(), emitsError(same(error))]),
    );
    verifyNever(() => audio.play());
    verifyNever(() => app.getAuthSession());
  });

  group('offline', () {
    late MockRepository repository;
    late MockCache cache;
    late MockAudio audio;
    late MockAppPort app;
    late StartChantingUseCase useCase;

    setUp(() {
      repository = MockRepository();
      cache = MockCache();
      audio = MockAudio();
      app = MockAppPort();
      when(() => audio.stop()).thenAnswer((_) async {});
      when(() => repository.queryAll()).thenThrow(Exception('offline'));
      useCase = StartChantingUseCase(
        chantRepo: repository,
        cacheChantsUseCase: cache,
        chantingAudioService: audio,
        chantingAppPort: app,
      );
    });

    test('falls back to cached chant list and plays cached chants', () async {
      final chant = chantFixture('chant');
      final resources = ChantLocalResourcesEntity(
        chant: chant,
        audioLocalPath: '/audio',
        lyricsLocalPath: '/lyrics',
        audioVersion: 2,
        lyricsVersion: 2,
      );
      final progress = CachingProgressEntity(progress: 1, results: [(chant: chant, localResources: resources)]);
      when(() => repository.queryAll(preferCache: true)).thenAnswer((_) async => [chant]);
      when(() => cache.execute(['chant'], [chant])).thenAnswer((_) => Stream.value(progress));
      when(() => audio.setup([resources])).thenAnswer((_) async => Duration.zero);
      when(() => audio.play()).thenAnswer((_) async {});
      when(() => app.getAuthSession()).thenAnswer((_) async => (userId: null, isAuthenticated: false));

      expect(await useCase.execute(['chant']).toList(), [progress]);
      verify(() => audio.play()).called(1);
    });

    test('throws offline exception when cached chant list is empty', () async {
      when(() => repository.queryAll(preferCache: true)).thenAnswer((_) async => []);

      await expectLater(useCase.execute(['chant']), emitsError(isA<ChantsUnavailableOfflineException>()));
      verifyNever(() => audio.play());
    });

    test('throws offline exception when a download is needed', () async {
      final chant = chantFixture('chant');
      when(() => repository.queryAll(preferCache: true)).thenAnswer((_) async => [chant]);
      when(() => cache.execute(['chant'], [chant])).thenAnswer((_) => Stream.error(Exception('network')));

      await expectLater(useCase.execute(['chant']), emitsError(isA<ChantsUnavailableOfflineException>()));
      verifyNever(() => audio.play());
    });
  });
}
