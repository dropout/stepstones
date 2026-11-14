import 'package:admin_stats/src/domain/entity/daily_global_stats_entity.dart';
import 'package:admin_stats/src/domain/entity/global_stats_entity.dart';

abstract interface class AdminStatsRepository {
  /// Emits the all-time totals and every later change to them.
  Stream<GlobalStatsEntity> watchAllTime();

  /// Loads the totals of each of [days] (UTC midnights), in the same order; days without sessions are zero.
  Future<List<DailyGlobalStatsEntity>> loadDays(List<DateTime> days);
}
