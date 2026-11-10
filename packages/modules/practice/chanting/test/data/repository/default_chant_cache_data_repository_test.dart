import 'dart:io';

import 'package:chanting/src/data/datasource/chant_cache_data_provider.dart';
import 'package:chanting/src/data/mapper/chant_cache_mapper.dart';
import 'package:chanting/src/data/repository/default_chant_cache_data_repository.dart';
import 'package:chanting/src/data/service/chant_cache_file_system.dart';
import 'package:chanting/src/domain/enum/cached_asset_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/cache_fixtures.dart';

class MockCacheDataProvider extends Mock implements ChantCacheDataProvider {}

void main() {
  test('maps cache rows at the repository boundary', () async {
    final provider = MockCacheDataProvider();
    final entry = cacheEntryFixture('chant', CachedAssetType.audio, '/cache/audio');
    final row = entry.toRow();
    registerFallbackValue(row);
    final repository = DefaultChantCacheDataRepository(
      chantCacheDataProvider: provider,
      chantCacheFileSystem: ChantCacheFileSystem(documentsDirectoryProvider: () async => Directory.systemTemp),
    );
    when(() => provider.readEntry('chant', CachedAssetType.audio)).thenAnswer((_) async => row);
    when(() => provider.upsertEntry(any())).thenAnswer((_) async {});

    expect(await repository.readEntry('chant', CachedAssetType.audio), entry);
    await repository.upsertEntry(entry);
    verify(() => provider.upsertEntry(row)).called(1);
  });
}
