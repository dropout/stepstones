import 'session_mapper.dart';
import '../../domain/service/session_app_port.dart';
import '../../public/model/update_profile_stats_result.dart';

extension UpdateProfileStatsResultMapper on ProfileUpdateResult {
  UpdateProfileStatsResult toApi() => UpdateProfileStatsResult(
    session: session.toApi(),
    oldProfile: oldProfile,
    updatedProfile: updatedProfile,
  );
}
