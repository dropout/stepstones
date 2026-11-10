import 'package:chanting/src/domain/enum/cached_asset_type.dart';
import 'package:chanting/src/domain/repository/chant_cache_data_repository.dart';
import 'package:chanting/src/domain/service/chant_cache_services.dart';
import 'package:chanting/src/domain/service/chant_cache_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/cache_fixtures.dart';

class MockCacheRepository extends Mock implements ChantCacheRepository {}

class MockFileAccess extends Mock implements ChantCacheFileAccess {}

void main() {
  test('preserves both existing entries when assets require replacement', () async {
    final repository = MockCacheRepository();
    final files = MockFileAccess();
    final audio = cacheEntryFixture('chant', CachedAssetType.audio, '/old/audio');
    final lyrics = cacheEntryFixture('chant', CachedAssetType.lyrics, '/old/lyrics');
    when(() => repository.readEntry('chant', CachedAssetType.audio)).thenAnswer((_) async => audio);
    when(() => repository.readEntry('chant', CachedAssetType.lyrics)).thenAnswer((_) async => lyrics);

    final result = await ChantCacheValidator(
      chantCacheRepo: repository,
      fileAccess: files,
    ).validate(chantFixture('chant'));

    expect(result.isValid, isFalse);
    expect(result.audioCacheEntry, audio);
    expect(result.lyricsCacheEntry, lyrics);
  });

  test('preserves valid and missing entries independently', () async {
    final repository = MockCacheRepository();
    final files = MockFileAccess();
    final audio = cacheEntryFixture('chant', CachedAssetType.audio, '/audio', version: 2);
    when(() => repository.readEntry('chant', CachedAssetType.audio)).thenAnswer((_) async => audio);
    when(() => repository.readEntry('chant', CachedAssetType.lyrics)).thenAnswer((_) async => null);
    when(() => files.exists('/audio')).thenAnswer((_) async => true);
    when(() => files.sha256('/audio')).thenAnswer((_) async => chantFixture('chant').metaData.audioSha256);
    when(() => files.size('/audio')).thenAnswer((_) async => 3);
    registerFallbackValue(audio);
    when(() => repository.upsertEntry(any())).thenAnswer((_) async {});

    final result = await ChantCacheValidator(
      chantCacheRepo: repository,
      fileAccess: files,
    ).validate(chantFixture('chant'));

    expect(result.isAudioCacheValid, isTrue);
    expect(result.isLyricsCacheValid, isFalse);
    expect(result.audioCacheEntry, audio);
    expect(result.lyricsCacheEntry, isNull);
    expect(result.audioCachePath, '/audio');
  });
}
