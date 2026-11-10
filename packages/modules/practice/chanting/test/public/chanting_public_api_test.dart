import 'package:chanting/chanting.dart';
import 'package:chanting/src/data/service/default_chanting_public_api.dart';
import 'package:chanting/src/domain/repository/chant_cache_data_repository.dart';
import 'package:chanting/src/domain/repository/chant_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/cache_fixtures.dart';

class MockChantRepository extends Mock implements ChantRepository {}

class MockChantCacheRepository extends Mock implements ChantCacheRepository {}

void main() {
  late MockChantRepository repository;
  late MockChantCacheRepository cache;
  late ChantingPublicApi api;

  setUp(() {
    repository = MockChantRepository();
    cache = MockChantCacheRepository();
    api = DefaultChantingPublicApi(chantRepository: repository, chantCacheRepository: cache);
  });

  test('loads public chant models and forwards the cache preference', () async {
    final entity = chantFixture('one');
    when(() => repository.queryAll(preferCache: false)).thenAnswer((_) async => [entity]);
    when(() => repository.queryAll(preferCache: true)).thenAnswer((_) async => [entity]);

    for (final preferCache in [false, true]) {
      final chant = (await api.loadChants(preferCache: preferCache)).single;
      expect(chant, isA<Chant>());
      expect(chant.id, entity.id);
      expect(chant.name, entity.name);
      expect(chant.blurHash, entity.blurHash);
      expect(chant.order, entity.order);
      expect(chant.length, entity.length);
      expect(chant.metaData.id, entity.metaData.id);
      expect(chant.metaData.audioVersion, entity.metaData.audioVersion);
      expect(chant.metaData.lyricsVersion, entity.metaData.lyricsVersion);
      expect(chant.metaData.coverVersion, entity.metaData.coverVersion);
      expect(chant.metaData.audioSha256, entity.metaData.audioSha256);
      expect(chant.metaData.lyricsSha256, entity.metaData.lyricsSha256);
      expect(chant.metaData.coverSha256, entity.metaData.coverSha256);
      expect(chant.metaData.audioBytes, entity.metaData.audioBytes);
      expect(chant.metaData.lyricsBytes, entity.metaData.lyricsBytes);
      expect(chant.metaData.coverBytes, entity.metaData.coverBytes);
      expect(chant.metaData.updatedAt, entity.metaData.updatedAt);
      verify(() => repository.queryAll(preferCache: preferCache)).called(1);
    }
  });

  test('maps successive catalogue updates and propagates stream errors', () async {
    final error = StateError('catalogue stream failed');
    when(() => repository.queryAllStream()).thenAnswer((_) async* {
      yield [chantFixture('one'), chantFixture('two')];
      yield [];
      throw error;
    });

    await expectLater(
      api.chantsStream,
      emitsInOrder([
        isA<List<Chant>>().having((chants) => chants.map((chant) => chant.id).toList(), 'ids', ['one', 'two']),
        isEmpty,
        emitsError(same(error)),
        emitsDone,
      ]),
    );
    verify(() => repository.queryAllStream()).called(1);
  });

  test('propagates catalogue load and cache clear errors', () async {
    final loadError = StateError('load failed');
    final clearError = StateError('clear failed');
    when(() => repository.queryAll(preferCache: false)).thenAnswer((_) async => throw loadError);
    when(() => cache.clearCache()).thenAnswer((_) async => throw clearError);

    await expectLater(api.loadChants(), throwsA(same(loadError)));
    await expectLater(api.clearCachedChants(), throwsA(same(clearError)));
    verify(() => cache.clearCache()).called(1);
  });

  test('delegates clearing cached files', () async {
    when(() => cache.clearCache()).thenAnswer((_) async {});
    await api.clearCachedChants();
    verify(() => cache.clearCache()).called(1);
    verifyNever(() => cache.deleteAllEntries());
  });
}
