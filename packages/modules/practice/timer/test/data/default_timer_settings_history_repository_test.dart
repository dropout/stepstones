import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer/src/data/repository/default_timer_settings_history_repository.dart';
import 'package:timer/src/domain/entity/timer_settings_entity.dart';
import 'package:timer/src/domain/entity/timer_settings_history_record_entity.dart';

import '../timer_mock_definitions.dart';


void main() {
  late MockTimerSettingsHistoryDataProvider firstProvider;
  late MockTimerSettingsHistoryDataProvider secondProvider;
  late DefaultTimerSettingsHistoryRepository repository;
  late List<String> requestedProfiles;

  setUp(() {
    firstProvider = MockTimerSettingsHistoryDataProvider();
    secondProvider = MockTimerSettingsHistoryDataProvider();
    requestedProfiles = [];
    repository = DefaultTimerSettingsHistoryRepository(
      providerFactory: (profileId) {
        requestedProfiles.add(profileId);
        return switch (profileId) {
          'first' => firstProvider,
          'second' => secondProvider,
          _ => throw ArgumentError.value(profileId),
        };
      },
    );
  });

  test('records settings with the requested profile and clock time', () async {
    const settings = TimerSettingsEntity();
    final now = DateTime(2026, 10, 1, 12);
    when(() => firstProvider.recordUse(settings, now)).thenAnswer((_) async {});

    await withClock(Clock.fixed(now), () => repository.recordTimerSettingsHistory('first', settings));

    expect(requestedProfiles, ['first']);
    verify(() => firstProvider.recordUse(settings, now)).called(1);
    verifyZeroInteractions(secondProvider);
  });

  test('queries the requested profile with the limit and deduplicates', () async {
    final newer = TimerSettingsHistoryRecordEntity(
      id: 'new',
      timerSettings: const TimerSettingsEntity(),
      useCount: 2,
      lastUsed: DateTime(2026, 10, 2),
    );
    final older = newer.copyWith(id: 'old', useCount: 3);
    when(() => secondProvider.query(limit: 5)).thenAnswer((_) async => [newer, older]);

    final records = await repository.query('second', limit: 5);

    expect(requestedProfiles, ['second']);
    expect(records, [newer.copyWith(useCount: 5)]);
    verify(() => secondProvider.query(limit: 5)).called(1);
    verifyZeroInteractions(firstProvider);
  });

  test('streams the requested profile and deduplicates each result', () async {
    final newer = TimerSettingsHistoryRecordEntity(
      id: 'new',
      timerSettings: const TimerSettingsEntity(),
      useCount: 1,
      lastUsed: DateTime(2026, 10, 2),
    );
    final older = newer.copyWith(id: 'old', useCount: 4);
    when(() => firstProvider.queryStream(limit: 20)).thenAnswer(
      (_) => Stream.fromIterable([
        [newer, older],
        [newer],
      ]),
    );

    final results = await repository.queryStream('first').toList();

    expect(requestedProfiles, ['first']);
    expect(results, [
      [newer.copyWith(useCount: 5)],
      [newer],
    ]);
    verify(() => firstProvider.queryStream(limit: 20)).called(1);
  });

  test('propagates provider failures', () async {
    final error = StateError('read failed');
    when(() => firstProvider.query(limit: 20)).thenThrow(error);

    expect(() => repository.query('first'), throwsA(same(error)));
  });
}
