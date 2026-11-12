import 'package:profile/src/data/mapper/profile_mapper.dart';
import 'package:profile/src/data/mapper/profile_session_mapper.dart';
import 'package:profile/src/domain/usecase/load_profile_stream_use_case.dart';
import 'package:profile/src/domain/usecase/load_profile_use_case.dart';
import 'package:profile/src/domain/usecase/update_profile_stats_with_session_use_case.dart';
import 'package:profile/src/public/api/profile_public_api.dart';
import 'package:profile/src/public/model/profile.dart';
import 'package:profile/src/public/model/profile_session.dart';


class DefaultProfilePublicApi implements ProfilePublicApi {

  final LoadProfileUseCase loadProfileUseCase;
  final LoadProfileStreamUseCase loadProfileStreamUseCase;
  final UpdateProfileStatsWithSessionUseCase updateProfileStatsWithSessionUseCase;

  DefaultProfilePublicApi({
    required this.loadProfileUseCase,
    required this.loadProfileStreamUseCase,
    required this.updateProfileStatsWithSessionUseCase,
  });

  @override
  Future<Profile> getProfile(String profileId, {bool preferCache = false}) => 
    loadProfileUseCase.execute(profileId, preferCache: preferCache)
      .then((profileEntity) => profileEntity.toApi());

  @override
  Stream<Profile> getProfileStream(String profileId, {bool filterCached = false}) =>
    loadProfileStreamUseCase.execute(profileId, filterCached: filterCached)
      .map((profileEntity) => profileEntity.toApi());

  @override
  Future<({Profile originalProfile, Profile updatedProfile})> updateProfileStatsWithSession(
    String profileId,
    ProfileSession session,
  ) async => updateProfileStatsWithSessionUseCase
    .execute(profileId, session.toDomain()).then((result) => (
    originalProfile: result.originalProfile.toApi(),
    updatedProfile: result.updatedProfile.toApi(),
  ));

}