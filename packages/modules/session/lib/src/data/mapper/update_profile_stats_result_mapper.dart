import 'session_mapper.dart';
import '../../domain/entity/update_profile_stats_result_entity.dart';
import '../../public/model/update_profile_stats_result.dart';

extension UpdateProfileStatsResultMapper on UpdateProfileStatsResultEntity {
  UpdateProfileStatsResult toApi() {
    return UpdateProfileStatsResult(
      session: session.toApi(),
      oldProfile: oldProfile,
      updatedProfile: updatedProfile,
    );
  }
}

extension UpdateProfileStatsResultEntityMapper on UpdateProfileStatsResult {
  UpdateProfileStatsResultEntity toDomain() {
    return UpdateProfileStatsResultEntity(
      session: session.toDomain(),
      oldProfile: oldProfile,
      updatedProfile: updatedProfile,
    );
  }
}
