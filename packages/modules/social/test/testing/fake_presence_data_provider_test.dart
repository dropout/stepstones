import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:social/src/data/datasource/presence_data_provider.dart';
import 'package:social/src/domain/entity/presence_query_options_entity.dart';
import 'package:social/testing.dart';

void main() {
  group('FakePresenceDataProvider', () {
    FakePresenceDataProvider create({
      int count = 10,
      double photoRatio = 0.5,
      bool failQueries = false,
      int seed = 1,
    }) => FakePresenceDataProvider(
      count: count,
      photoRatio: photoRatio,
      latency: Duration.zero,
      failQueries: failQueries,
      seed: seed,
    );

    test('query returns newest first up to limit', () async {
      final result = await create().query(
        const PresenceQueryOptionsEntity(limit: 4),
      );

      expect(result, hasLength(4));
      for (var i = 1; i < result.length; i++) {
        expect(result[i - 1].startedAt.isAfter(result[i].startedAt), isTrue);
      }
    });

    test('query pages after lastDocumentId', () async {
      final provider = create();
      final firstPage = await provider.query(
        const PresenceQueryOptionsEntity(limit: 4),
      );
      final secondPage = await provider.query(
        PresenceQueryOptionsEntity(limit: 4, lastDocumentId: firstPage.last.id),
      );
      final lastPage = await provider.query(
        PresenceQueryOptionsEntity(limit: 4, lastDocumentId: secondPage.last.id),
      );

      final ids = [...firstPage, ...secondPage, ...lastPage].map((p) => p.id);
      expect(ids.toSet(), hasLength(10));
      expect(lastPage, hasLength(2));
    });

    test('query excludes presences outside the window', () async {
      final provider = FakePresenceDataProvider(
        count: 10,
        spread: const Duration(minutes: 100),
        latency: Duration.zero,
      );

      final result = await provider.query(
        const PresenceQueryOptionsEntity(
          limit: 100,
          windowSize: Duration(minutes: 45),
        ),
      );

      expect(result, hasLength(5));
    });

    test('query throws when failQueries is set', () async {
      expect(
        () => create(failQueries: true).query(const PresenceQueryOptionsEntity()),
        throwsStateError,
      );
    });

    test('photoUrlFor resolves only profiles with a blurhash', () async {
      final result = await create().query(
        const PresenceQueryOptionsEntity(limit: 100),
      );
      final provider = create();

      for (final presence in result) {
        final url = provider.photoUrlFor('/profiles/${presence.profile.id}/photo.jpg');
        expect(url != null, presence.profile.photoBlurhash != null);
      }
      expect(result.any((p) => p.profile.photoBlurhash != null), isTrue);
      expect(result.any((p) => p.profile.photoBlurhash == null), isTrue);
    });

    test('same seed generates the same profiles', () async {
      const options = PresenceQueryOptionsEntity(limit: 100);
      final first = await create(seed: 7).query(options);
      final second = await create(seed: 7).query(options);

      expect(
        first.map((p) => p.profile.copyWith()),
        second.map((p) => p.profile.copyWith()),
      );
    });

    test('useFakePresenceDataProvider replaces the registered provider', () async {
      final getIt = GetIt.asNewInstance();
      getIt.registerSingleton<PresenceDataProvider>(create(seed: 1));
      final fake = create(seed: 2);

      await getIt.useFakePresenceDataProvider(fake);

      expect(getIt.get<PresenceDataProvider>(), same(fake));
    });
  });
}
