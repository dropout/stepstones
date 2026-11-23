import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:social/src/data/datasource/presence_data_provider.dart';
import 'package:social/src/domain/entity/presence_query_options_entity.dart';
import 'package:social/testing.dart';

class _MockStorageDataProvider extends Mock implements StorageDataProvider {}

void main() {
  group('useFakePresenceForRecording', () {
    late GetIt getIt;
    late _MockStorageDataProvider storage;

    setUp(() {
      getIt = GetIt.asNewInstance();
      storage = _MockStorageDataProvider();
      getIt.registerSingleton<StorageDataProvider>(storage);
      getIt.registerSingleton<ResourceResolver>(
        DefaultResourceResolver(storageDataProvider: storage),
      );
      when(() => storage.getDownloadURL(any()))
        .thenAnswer((_) async => 'https://storage.example/real.jpg');
    });

    test('fake profiles resolve to portraits, other paths to storage', () async {
      await getIt.useFakePresenceForRecording(latency: Duration.zero);
      final presences = await getIt.get<PresenceDataProvider>().query(
        const PresenceQueryOptionsEntity(limit: 100),
      );
      final withPhoto = presences.firstWhere((p) => p.profile.photoBlurhash != null);
      final resolver = getIt.get<ResourceResolver>();

      expect(
        await resolver.resolveStoragePath('/profiles/${withPhoto.profile.id}/photo.jpg'),
        startsWith('https://randomuser.me/'),
      );
      expect(
        await resolver.resolveStoragePath('/profiles/real-user/photo.jpg'),
        'https://storage.example/real.jpg',
      );
    });
  });
}
