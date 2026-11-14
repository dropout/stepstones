import 'package:core/core.dart';
import 'package:profile/src/domain/entity/profile_entity.dart';
import 'package:profile/src/domain/repository/profile_repository.dart';

/// Development helper that puts a profile back into its pre-onboarding state.
class ResetOnboardingUseCase {
  final ProfileRepository profileRepository;
  final SharedPreferencesService preferences;

  ResetOnboardingUseCase({
    required this.profileRepository,
    required this.preferences,
  });

  Future<void> execute(ProfileEntity profile) async {
    await profileRepository.update(
      profile.copyWith(completed: false, location: null),
    );
    await preferences.remove(
      key: SharedPreferencesKey.locationPromptDismissed.name,
    );
  }
}
