import 'package:admin_stats/src/domain/entity/global_stats_entity.dart';

const _typePrefix = 'type_';

/// Maps one shard document; unknown or malformed fields count as zero.
GlobalStatsEntity globalStatsShardFromFirestore(Map<String, dynamic> data) => GlobalStatsEntity(
  totalSessions: _int(data['totalSessions']),
  totalDuration: Duration(seconds: _int(data['totalDurationInSeconds'])),
  sessionsByType: {
    for (final MapEntry(:key, :value) in data.entries)
      if (key.startsWith(_typePrefix) && key.length > _typePrefix.length)
        key.substring(_typePrefix.length): _int(value),
  },
);

/// Document id of a day's stats, matching the Cloud Function's UTC bucketing.
String dailyGlobalStatsDocumentId(DateTime day) {
  final utc = day.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  return 'daily_${utc.year}-${two(utc.month)}-${two(utc.day)}';
}

int _int(Object? value) => value is num ? value.toInt() : 0;
