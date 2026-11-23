import 'package:core/core.dart';
import 'package:get_it/get_it.dart';

import 'package:social/src/testing/fake_presence_data_provider.dart';

/// Swaps presence data and profile photos for fakes so the real app can be demoed or screen recorded.
extension FakePresenceRecording on GetIt {
  /// Call after all module dependencies are registered and before services are built.
  /// Only fake profiles get public portrait URLs; every other storage path resolves normally.
  Future<void> useFakePresenceForRecording({
    int count = 40,
    double photoRatio = 0.85,
    Duration spread = const Duration(minutes: 60),
    Duration latency = const Duration(milliseconds: 600),
    int seed = 1,
  }) async {
    final dataProvider = FakePresenceDataProvider(
      count: count,
      photoRatio: photoRatio,
      spread: spread,
      latency: latency,
      seed: seed,
    );
    await useFakePresenceDataProvider(dataProvider);

    if (isRegistered<ResourceResolver>()) {
      await unregister<ResourceResolver>();
    }
    registerLazySingleton<ResourceResolver>(
      () => FakeProfilePhotoResourceResolver(
        storageDataProvider: get<StorageDataProvider>(),
        dataProvider: dataProvider,
      ),
    );
  }
}

/// Resolves fake profile photos to portrait URLs and defers everything else to storage.
class FakeProfilePhotoResourceResolver extends ResourceResolver {
  final FakePresenceDataProvider dataProvider;

  FakeProfilePhotoResourceResolver({
    required super.storageDataProvider,
    required this.dataProvider,
  });

  @override
  Future<String> resolveStoragePath(String path) async =>
    dataProvider.photoUrlFor(path) ?? await super.resolveStoragePath(path);
}
