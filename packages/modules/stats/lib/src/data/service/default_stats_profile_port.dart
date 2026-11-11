import 'package:profile/profile.dart';
import 'package:stats/src/domain/service/stats_profile_port.dart';

class DefaultStatsProfilePort implements StatsProfilePort {
  final ProfilePublicApi profilePublicApi;

  const DefaultStatsProfilePort({required this.profilePublicApi});

  @override
  Future<int> getConsecutiveDaysCount(String profileId) async {
    final profile = await profilePublicApi.getProfile(
      profileId,
      preferCache: true,
    );
    return profile.statsReport.consecutiveDays.current;
  }
}
