import 'package:stats/src/domain/entity/stats_bucket_entity.dart';
import 'package:stats/src/domain/enum/stats_entity_granularity.dart';
import 'package:stats/src/domain/repository/stats_repository.dart';

/// Use case for querying statistics buckets from the repository.
class QuerySessionStatsUseCase {

  final StatsRepository repository;

  const QuerySessionStatsUseCase({
    required this.repository,
  });

  Future<List<StatsBucketEntity>> execute({
    required String profileId, 
    required DateTime from,
    required DateTime to,
    required StatsEntityGranularity granularity,
  }) async => repository.queryBuckets(
      profileId,
      from: from,
      to: to,
      granularity: granularity,
    );

}
