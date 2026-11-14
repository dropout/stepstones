import 'package:flutter_test/flutter_test.dart';

import 'package:admin_stats/src/data/mapper/global_stats_mapper.dart';
import 'package:admin_stats/src/domain/entity/global_stats_entity.dart';

void main() {
  test('maps a shard written by the aggregation function', () {
    final stats = globalStatsShardFromFirestore({
      'totalSessions': 12,
      'totalDurationInSeconds': 5400,
      'type_timer': 9,
      'type_chanting': 3,
    });

    expect(
      stats,
      const GlobalStatsEntity(
        totalSessions: 12,
        totalDuration: Duration(minutes: 90),
        sessionsByType: {'timer': 9, 'chanting': 3},
      ),
    );
  });

  test('treats missing and malformed fields as zero', () {
    final stats = globalStatsShardFromFirestore({'totalSessions': 'many', 'type_': 4, 'type_timer': null});

    expect(stats.totalSessions, 0);
    expect(stats.totalDuration, Duration.zero);
    expect(stats.sessionsByType, {'timer': 0});
  });

  test('sums shards including types only some of them hold', () {
    final total = GlobalStatsEntity.sum(const [
      GlobalStatsEntity(totalSessions: 2, totalDuration: Duration(minutes: 10), sessionsByType: {'timer': 2}),
      GlobalStatsEntity(
        totalSessions: 3,
        totalDuration: Duration(minutes: 5),
        sessionsByType: {'timer': 1, 'chanting': 2},
      ),
    ]);

    expect(
      total,
      const GlobalStatsEntity(
        totalSessions: 5,
        totalDuration: Duration(minutes: 15),
        sessionsByType: {'timer': 3, 'chanting': 2},
      ),
    );
    expect(GlobalStatsEntity.sum(const []), const GlobalStatsEntity());
  });

  test('builds the daily document id from the UTC day', () {
    expect(dailyGlobalStatsDocumentId(DateTime.utc(2026, 3, 7)), 'daily_2026-03-07');
    // 23:30 at UTC-5 is already the next day in UTC.
    expect(dailyGlobalStatsDocumentId(DateTime.parse('2026-03-07T23:30:00-05:00')), 'daily_2026-03-08');
  });
}
