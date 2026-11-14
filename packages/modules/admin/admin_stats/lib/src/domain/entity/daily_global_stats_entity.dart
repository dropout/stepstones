import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin_stats/src/domain/entity/global_stats_entity.dart';

part 'daily_global_stats_entity.freezed.dart';

@freezed
sealed class DailyGlobalStatsEntity with _$DailyGlobalStatsEntity {
  /// [day] is a UTC midnight; sessions are bucketed by the UTC day they ended on.
  const factory DailyGlobalStatsEntity({required DateTime day, required GlobalStatsEntity stats}) =
      _DailyGlobalStatsEntity;
}
