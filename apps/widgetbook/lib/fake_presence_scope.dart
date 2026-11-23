import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:social/social.dart';
import 'package:social/testing.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:core/core.dart';
import 'package:stepstones_widgetbook/get_it_scope.dart';

class _MockStorageDataProvider extends Mock implements StorageDataProvider {}

/// Knob-driven settings for [FakePresenceDataProvider] and fake photo loading.
class FakePresenceOptions {
  final int count;
  final double photoRatio;
  final Duration queryLatency;
  final Duration imageLatency;
  final bool failQueries;
  final int seed;

  const FakePresenceOptions({
    required this.count,
    required this.photoRatio,
    required this.queryLatency,
    required this.imageLatency,
    required this.failQueries,
    required this.seed,
  });

  factory FakePresenceOptions.fromKnobs(BuildContext context) {
    return FakePresenceOptions(
      count: context.knobs.int.slider(
        label: 'Presences in backend',
        initialValue: 40,
        min: 0,
        max: 80,
      ),
      photoRatio: context.knobs.double.slider(
        label: 'Photo ratio',
        initialValue: 0.8,
        min: 0,
        max: 1,
        divisions: 10,
      ),
      queryLatency: Duration(milliseconds: context.knobs.int.slider(
        label: 'Query latency (ms)',
        initialValue: 600,
        min: 0,
        max: 5000,
      )),
      imageLatency: Duration(milliseconds: context.knobs.int.slider(
        label: 'Image URL latency (ms)',
        initialValue: 300,
        min: 0,
        max: 5000,
      )),
      failQueries: context.knobs.boolean(
        label: 'Fail queries',
        initialValue: false,
      ),
      seed: context.knobs.int.input(
        label: 'Seed',
        initialValue: 1,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
    other is FakePresenceOptions &&
    other.count == count &&
    other.photoRatio == photoRatio &&
    other.queryLatency == queryLatency &&
    other.imageLatency == imageLatency &&
    other.failQueries == failQueries &&
    other.seed == seed;

  @override
  int get hashCode => Object.hash(
    count, photoRatio, queryLatency, imageLatency, failQueries, seed,
  );
}

/// Registers the real social module with a fake presence data provider and serves local portraits.
/// Adds a replay button; replaying or changing [options] or [resetKey] remounts [builder] with fresh dependencies.
class FakePresenceScope extends StatefulWidget {
  final FakePresenceOptions options;
  final Object? resetKey;
  final WidgetBuilder builder;

  /// Registers dependencies the previewed widget needs beyond the social module.
  final void Function(GetIt sl)? registerExtraDependencies;

  const FakePresenceScope({
    required this.options,
    required this.builder,
    this.resetKey,
    this.registerExtraDependencies,
    super.key,
  });

  @override
  State<FakePresenceScope> createState() => _FakePresenceScopeState();
}

class _FakePresenceScopeState extends State<FakePresenceScope> {
  int _replayCount = 0;

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final dataProvider = FakePresenceDataProvider(
      count: options.count,
      photoRatio: options.photoRatio,
      latency: options.queryLatency,
      failQueries: options.failQueries,
      seed: options.seed,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: Provider<Services>.value(
            value: _withFakeStorage(context.services, dataProvider, options.imageLatency),
            child: GetItScope(
              key: ValueKey(Object.hash(_replayCount, options, widget.resetKey)),
              setupDependencies: (sl) async {
                await sl.reset();
                sl.registerLazySingleton<CrashlyticsService>(MockCrashlyticsService.new);
                sl.registerSocialModuleDependencies();
                await sl.useFakePresenceDataProvider(dataProvider);
                widget.registerExtraDependencies?.call(sl);
              },
              child: Builder(builder: widget.builder),
            ),
          ),
        ),
        Positioned(
          right: DesignSpec.paddingLg,
          bottom: DesignSpec.paddingLg,
          child: FloatingActionButton.small(
            onPressed: () => setState(() => _replayCount++),
            tooltip: 'Replay',
            child: const Icon(Icons.replay),
          ),
        ),
      ],
    );
  }
}

const _portraitFolders = {
  FakePortraitGender.male: 'assets/images/portraits/men/',
  FakePortraitGender.female: 'assets/images/portraits/women/',
};
const _fallbackPortrait = 'assets/images/avatar.jpg';

/// Same-origin asset URLs per gender, since public portrait hosts block cross-origin image fetches on web.
final Future<Map<FakePortraitGender, List<String>>> _portraitUrls = () async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets = manifest.listAssets();
  return _portraitFolders.map((gender, folder) {
    final keys = assets.where((key) => key.startsWith(folder)).toList()..sort();
    return MapEntry(
      gender,
      (keys.isEmpty ? [_fallbackPortrait] : keys)
        .map((key) => Uri.base.resolve('assets/$key').toString())
        .toList(),
    );
  });
}();

/// Copies [base] with a real resolver that serves local portraits for profiles that have a photo.
Services _withFakeStorage(
  Services base,
  FakePresenceDataProvider dataProvider,
  Duration latency,
) {
  final storage = _MockStorageDataProvider();
  when(() => storage.getDownloadURL(any())).thenAnswer((invocation) async {
    await Future<void>.delayed(latency);
    final path = invocation.positionalArguments.first as String;
    final portrait = dataProvider.portraitFor(path);
    if (portrait == null) {
      throw StateError('No fake photo for $path');
    }
    final urls = (await _portraitUrls)[portrait.gender]!;
    return urls[portrait.index % urls.length];
  });

  final services = MockServices();
  when(() => services.hapticsService).thenReturn(base.hapticsService);
  when(() => services.overlayService).thenReturn(base.overlayService);
  when(() => services.shaderService).thenReturn(base.shaderService);
  when(() => services.crashlyticsService).thenReturn(base.crashlyticsService);
  when(() => services.resourceResolver)
    .thenReturn(DefaultResourceResolver(storageDataProvider: storage));
  return services;
}
