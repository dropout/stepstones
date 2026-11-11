import 'package:stats/src/domain/entity/stats_session_entity.dart';
import 'package:stats/src/domain/repository/stats_repository.dart';
import 'package:stats/src/domain/service/stats_profile_port.dart';

class LogSessionStatsUseCase {

  final StatsRepository statsRepository;
  final StatsProfilePort profilePort;

  const LogSessionStatsUseCase({
    required this.statsRepository,
    required this.profilePort,
  });

  Future<void> execute(
    String profileId,
    StatsSessionEntity session,
  ) async {
    final consecutiveDaysCount =
        await profilePort.getConsecutiveDaysCount(profileId);
    return statsRepository.logSessionStats(
      profileId,
      session,
      consecutiveDaysCount,
    );
  }
  
}