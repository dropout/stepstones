import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:core/core.dart';
import 'package:get_it/get_it.dart';

import 'package:social/src/data/datasource/presence_data_provider.dart';
import 'package:social/src/domain/entity/presence_entity.dart';
import 'package:social/src/domain/entity/presence_query_options_entity.dart';
import 'package:social/src/domain/entity/social_profile_entity.dart';

/// Swaps the registered presence data provider for a fake, keeping the rest of the module real.
extension FakePresenceDependencyInjection on GetIt {
  Future<void> useFakePresenceDataProvider(FakePresenceDataProvider dataProvider) async {
    if (isRegistered<PresenceDataProvider>()) {
      await unregister<PresenceDataProvider>();
    }
    registerSingleton<PresenceDataProvider>(dataProvider);
  }
}

enum FakePortraitGender { male, female }

/// Portrait assigned to a fake profile; [index] is stable per seed.
class FakePortrait {
  final FakePortraitGender gender;
  final int index;

  const FakePortrait({required this.gender, required this.index});

  /// Public portrait URL; hosts block cross-origin fetches, so web previews should map to local assets.
  String get url => 'https://randomuser.me/api/portraits/'
    '${gender == FakePortraitGender.male ? 'men' : 'women'}/${index % 100}.jpg';
}

/// In-memory [PresenceDataProvider] with seeded fake profiles, for previews and tests.
class FakePresenceDataProvider implements PresenceDataProvider {
  static const _maleNames = ['James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas', 'Charles', 'Christopher', 'Maximilian'];
  static const _femaleNames = ['Olivia', 'Ava', 'Sophia', 'Isabella', 'Mia', 'Amelia', 'Harper', 'Evelyn', 'Abigail', 'Ella', 'Charlotte', 'Bo'];
  static const _lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Martinez', 'Wilson', 'Anderson', 'Taylor'];
  static const _blurhashes = [
    'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
    'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
    'L6PZfSi_.AyE_3t7t7R**0o#DgR4',
    'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.',
  ];

  /// Simulated round trip of every call.
  Duration latency;

  /// When true, every query throws, like an unreachable backend.
  bool failQueries;

  final List<PresenceEntity> _items;
  final Map<String, FakePortrait> _portraits;

  FakePresenceDataProvider._(this._items, this._portraits, this.latency, this.failQueries);

  /// Creates [count] presences started within [spread] before now, newest first.
  /// [photoRatio] is the share of profiles that have a profile photo.
  factory FakePresenceDataProvider({
    int count = 40,
    double photoRatio = 0.8,
    Duration spread = const Duration(minutes: 110),
    Duration latency = const Duration(milliseconds: 600),
    bool failQueries = false,
    int seed = 1,
  }) {
    final random = Random(seed);
    final now = clock.now();
    final portraits = <String, FakePortrait>{};
    final step = count > 1 ? spread ~/ count : Duration.zero;
    final items = List.generate(count, (index) {
      final isMale = random.nextBool();
      final hasPhoto = random.nextDouble() < photoRatio;
      // Presence documents are keyed by profile id in production.
      final id = 'fake-profile-$index';
      if (hasPhoto) {
        portraits[id] = FakePortrait(
          gender: isMale ? FakePortraitGender.male : FakePortraitGender.female,
          index: random.nextInt(100),
        );
      }
      String pick(List<String> values) => values[random.nextInt(values.length)];
      return PresenceEntity(
        id: id,
        profile: SocialProfileEntity(
          id: id,
          firstName: pick(isMale ? _maleNames : _femaleNames),
          lastName: pick(_lastNames),
          photoBlurhash: hasPhoto ? pick(_blurhashes) : null,
        ),
        startedAt: now.subtract(step * index),
      );
    });
    return FakePresenceDataProvider._(items, portraits, latency, failQueries);
  }

  /// Portrait for a profile photo storage path, or null when the profile has none.
  FakePortrait? portraitFor(String storagePath) {
    final profileId = RegExp(r'^/?profiles/([^/]+)/').firstMatch(storagePath)?.group(1);
    return _portraits[profileId];
  }

  /// Portrait URL for a profile photo storage path, or null when the profile has none.
  String? photoUrlFor(String storagePath) => portraitFor(storagePath)?.url;

  @override
  Future<List<PresenceEntity>> query(PresenceQueryOptionsEntity queryOptions) async {
    await _roundTrip();
    if (failQueries) {
      throw StateError('FakePresenceDataProvider: query failed on purpose');
    }
    final threshold = clock.now().subtract(queryOptions.windowSize);
    final inWindow = _items
      .where((presence) => !presence.startedAt.isBefore(threshold))
      .toList();
    final lastIndex = queryOptions.lastDocumentId == null
      ? -1
      : inWindow.indexWhere((presence) => presence.id == queryOptions.lastDocumentId);
    return inWindow.skip(lastIndex + 1).take(queryOptions.limit).toList();
  }

  @override
  Stream<List<PresenceEntity>> queryStream(PresenceQueryOptionsEntity queryOptions) =>
    Stream.fromFuture(query(queryOptions));

  @override
  Future<void> create(PresenceEntity item) async {
    await _roundTrip();
    _items
      ..removeWhere((presence) => presence.id == item.id)
      ..insert(0, item);
  }

  @override
  Future<PresenceEntity> read(String id, {bool preferCache = false}) async {
    await _roundTrip();
    return _items.firstWhere(
      (presence) => presence.id == id,
      orElse: () => throw DocumentNotFoundException(message: 'Presence $id not found'),
    );
  }

  @override
  Stream<PresenceEntity> readStream(String id, {bool filterCached = false}) =>
    Stream.fromFuture(read(id));

  @override
  Future<void> update(PresenceEntity item) async {
    await _roundTrip();
    final index = _items.indexWhere((presence) => presence.id == item.id);
    if (index < 0) {
      throw DocumentNotFoundException(message: 'Presence ${item.id} not found');
    }
    _items[index] = item;
  }

  @override
  Future<void> delete(String id) async {
    await _roundTrip();
    _items.removeWhere((presence) => presence.id == id);
  }

  @override
  Future<bool> exists(String id) async {
    await _roundTrip();
    return _items.any((presence) => presence.id == id);
  }

  Future<void> _roundTrip() =>
    latency == Duration.zero ? Future.value() : Future.delayed(latency);
}
