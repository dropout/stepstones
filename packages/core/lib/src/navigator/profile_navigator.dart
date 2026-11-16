import 'package:core/src/navigator/base_navigator.dart';

/// Why the onboarding wizard is shown; selects its intro message.
enum OnboardingIntent { firstSignIn, completeProfile }

abstract class ProfileNavigator extends BaseNavigator {
  
  const ProfileNavigator(super.router);

  Future<void> navigateToProfile(String profileId, {NavigationType type = .push});
  Future<void> navigateToOnboarding(
    String profileId, {
    OnboardingIntent intent = .firstSignIn,
    NavigationType type = .push,
  });
  Future<void> navigateToProfileSettings(String profileId, {NavigationType type = .push});
  Future<void> navigateToProfileEdit(String profileId, {NavigationType type = .push});
  Future<void> navigateToProfileDelete(String profileId, {NavigationType type = .push});

}
