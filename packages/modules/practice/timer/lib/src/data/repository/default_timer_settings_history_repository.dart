import 'package:clock/clock.dart';
import 'package:timer/src/data/datasource/timer_settings_history_data_provider.dart';
import 'package:timer/src/domain/entity/timer_settings_entity.dart';
import 'package:timer/src/domain/entity/timer_settings_history_record_entity.dart';
import 'package:timer/src/domain/repository/timer_settings_history_repository.dart';

class DefaultTimerSettingsHistoryRepository
    implements TimerSettingsHistoryRepository {

  final TimerSettingsHistoryDataProviderFactory providerFactory;

  DefaultTimerSettingsHistoryRepository({required this.providerFactory});

  @override
  Future<void> recordTimerSettingsHistory(
    String profileId,
    TimerSettingsEntity timerSettings,
  ) async {
    await providerFactory(profileId).recordUse(timerSettings, clock.now());
  }

  @override
  Future<List<TimerSettingsHistoryRecordEntity>> query(
    String profileId,
    {int limit = 20}
  ) {
    return providerFactory(profileId).query(limit: limit)
      .then(dedupeTimerSettingsHistory);
  }

  @override
  Stream<List<TimerSettingsHistoryRecordEntity>> queryStream(
    String profileId,
    {int limit = 20}
  ) {
    return providerFactory(profileId).queryStream(limit: limit)
      .map(dedupeTimerSettingsHistory);
  }

}

/// Merges records whose settings resolve to the same id, e.g. legacy ids or
/// removed sounds that now decode to defaults. Input must be ordered by recency.
List<TimerSettingsHistoryRecordEntity> dedupeTimerSettingsHistory(
  List<TimerSettingsHistoryRecordEntity> records,
) {
  final merged = <String, TimerSettingsHistoryRecordEntity>{};
  for (final record in records) {
    final key = record.timerSettings.id;
    final existing = merged[key];
    merged[key] = existing == null
      ? record
      : existing.copyWith(useCount: existing.useCount + record.useCount);
  }
  return merged.values.toList();
}
