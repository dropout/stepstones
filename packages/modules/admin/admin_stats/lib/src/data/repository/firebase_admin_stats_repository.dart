import 'package:firebase_provider/firebase_provider.dart';

import 'package:admin_stats/src/data/mapper/global_stats_mapper.dart';
import 'package:admin_stats/src/domain/entity/daily_global_stats_entity.dart';
import 'package:admin_stats/src/domain/entity/global_stats_entity.dart';
import 'package:admin_stats/src/domain/repository/admin_stats_repository.dart';

class FirebaseAdminStatsRepository implements AdminStatsRepository {
  final FirebaseFirestore firestore;

  const FirebaseAdminStatsRepository({required this.firestore});

  // Counters are sharded; the stats documents themselves hold no fields.
  CollectionReference<Map<String, dynamic>> _shards(String statsId) =>
      firestore.collection('global_stats').doc(statsId).collection('shards');

  GlobalStatsEntity _sum(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      GlobalStatsEntity.sum([for (final doc in snapshot.docs) globalStatsShardFromFirestore(doc.data())]);

  @override
  Stream<GlobalStatsEntity> watchAllTime() => _shards('all_time').snapshots().map(_sum);

  @override
  Future<List<DailyGlobalStatsEntity>> loadDays(List<DateTime> days) => Future.wait([
    for (final day in days)
      _shards(dailyGlobalStatsDocumentId(day))
          .get()
          .then((snapshot) => DailyGlobalStatsEntity(day: day, stats: _sum(snapshot))),
  ]);
}
