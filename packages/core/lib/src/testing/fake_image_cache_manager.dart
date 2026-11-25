import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mocktail/mocktail.dart';

/// A [BaseCacheManager] for widget tests that never touches sqflite,
/// path_provider or the network. Images stay in their loading state.
class FakeImageCacheManager extends Fake implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream.empty();
}
