import 'package:chanting/src/domain/entity/cache_validation_result_entity.dart';
import 'package:chanting/src/domain/entity/caching_progress_entity.dart';
import 'package:chanting/src/domain/entity/chant_entity.dart';
import 'package:chanting/src/domain/entity/chant_local_resources_entity.dart';
import 'package:chanting/src/domain/repository/chant_cache_data_repository.dart';
import 'package:chanting/src/domain/service/chant_cache_services.dart';
import 'package:chanting/src/domain/usecase/cache_chants_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/cache_fixtures.dart';

class MockCacheRepository extends Mock implements ChantCacheRepository {}

class MockValidator extends Mock implements ChantCacheValidationService {}

class MockDownloader extends Mock implements ChantAssetDownloadService {}

class MockResolver extends Mock implements ChantLocalResourcesService {}

void main() {
  late MockCacheRepository repository;
  late MockValidator validator;
  late MockDownloader downloader;
  late MockResolver resolver;
  late CacheChantsUseCase useCase;

  setUpAll(() {
    registerFallbackValue(chantFixture('fallback'));
    registerFallbackValue(<CacheValidationResultEntity>[]);
  });

  setUp(() {
    repository = MockCacheRepository();
    validator = MockValidator();
    downloader = MockDownloader();
    resolver = MockResolver();
    useCase = CacheChantsUseCase(
      chantCacheRepo: repository,
      chantCacheValidator: validator,
      chantAssetDownloader: downloader,
      localResourceResolver: resolver,
    );
    when(() => repository.ensureCacheDirectories()).thenAnswer((_) async {});
    when(() => resolver.resolve(any())).thenAnswer((invocation) async {
      final chant = invocation.positionalArguments.single as ChantEntity;
      return ChantLocalResourcesEntity(
        chant: chant,
        audioLocalPath: '${chant.id}.mp3',
        lyricsLocalPath: '${chant.id}.ass',
        audioVersion: 2,
        lyricsVersion: 2,
      );
    });
  });

  test('validates unique chants and preserves the requested playlist order', () async {
    final a = chantFixture('a');
    final b = chantFixture('b');
    when(() => validator.validate(any())).thenAnswer(
      (invocation) async => CacheValidationResultEntity(
        chant: invocation.positionalArguments.single as ChantEntity,
        isAudioCacheValid: true,
        isLyricsCacheValid: true,
      ),
    );

    final progress = await useCase.execute(['b', 'a', 'b'], [a, b]).toList();

    expect(progress, hasLength(1));
    expect(progress.single.progress, 1);
    expect(progress.single.results.map((result) => result.chant.id), ['b', 'a', 'b']);
    verify(() => validator.validate(a)).called(1);
    verify(() => validator.validate(b)).called(1);
    verifyNever(() => downloader.download(any()));
  });

  test('keeps progress below completion until downloads finish', () async {
    final chant = chantFixture('a');
    final invalid = CacheValidationResultEntity(chant: chant, isAudioCacheValid: false, isLyricsCacheValid: true);
    when(() => validator.validate(chant)).thenAnswer((_) async => invalid);
    when(() => downloader.download([invalid])).thenAnswer(
      (_) => Stream.fromIterable([
        const CachingProgressEntity(progress: 0.5, totalTasks: 1),
        const CachingProgressEntity(progress: 1, totalTasks: 1, completedTasks: 1),
      ]),
    );

    final progress = await useCase.execute(['a'], [chant]).toList();

    expect(progress.map((event) => event.progress), [0.5, 0.99, 1.0]);
    expect(progress.take(2).every((event) => event.results.isEmpty), isTrue);
    expect(progress.last.results.single.chant, chant);
    expect(progress.last.completedTasks, 1);
  });

  test('propagates download failures without reporting completion', () async {
    final chant = chantFixture('a');
    final invalid = CacheValidationResultEntity(chant: chant, isAudioCacheValid: false, isLyricsCacheValid: true);
    when(() => validator.validate(chant)).thenAnswer((_) async => invalid);
    when(() => downloader.download([invalid])).thenAnswer((_) => Stream.error(StateError('download failed')));

    await expectLater(useCase.execute(['a'], [chant]), emitsError(isA<StateError>()));
    verifyNever(() => resolver.resolve(any()));
  });

  test('reports an unknown chant', () async {
    await expectLater(useCase.execute(['missing'], []), emitsError(isA<StateError>()));
    verifyNever(() => downloader.download(any()));
  });

  test('does not report success when the download service emits no progress', () async {
    final chant = chantFixture('a');
    final invalid = CacheValidationResultEntity(chant: chant, isAudioCacheValid: false, isLyricsCacheValid: true);
    when(() => validator.validate(chant)).thenAnswer((_) async => invalid);
    when(() => downloader.download([invalid])).thenAnswer((_) => const Stream.empty());

    await expectLater(useCase.execute(['a'], [chant]), emitsError(isA<StateError>()));
    verifyNever(() => resolver.resolve(any()));
  });
}
