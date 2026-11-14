import 'package:freezed_annotation/freezed_annotation.dart';

part 'global_stats_entity.freezed.dart';

/// Aggregated session counters, either all-time or for one day.
@freezed
sealed class GlobalStatsEntity with _$GlobalStatsEntity {
  const GlobalStatsEntity._();

  const factory GlobalStatsEntity({
    @Default(0) int totalSessions,
    @Default(Duration.zero) Duration totalDuration,
    @Default({}) Map<String, int> sessionsByType,
  }) = _GlobalStatsEntity;

  GlobalStatsEntity operator +(GlobalStatsEntity other) => GlobalStatsEntity(
    totalSessions: totalSessions + other.totalSessions,
    totalDuration: totalDuration + other.totalDuration,
    sessionsByType: {
      for (final type in {...sessionsByType.keys, ...other.sessionsByType.keys})
        type: (sessionsByType[type] ?? 0) + (other.sessionsByType[type] ?? 0),
    },
  );

  static GlobalStatsEntity sum(Iterable<GlobalStatsEntity> parts) =>
      parts.fold(const GlobalStatsEntity(), (total, part) => total + part);
}
