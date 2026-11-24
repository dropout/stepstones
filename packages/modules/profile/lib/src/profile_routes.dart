import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import 'package:core/core.dart';
import 'package:profile/src/presentation/view/screen/profile_settings_screen.dart';
import 'package:profile/src/presentation/view/screen/profile_screen.dart';
import 'package:profile/src/presentation/view/screen/onboarding_wizard_screen.dart';
import 'package:profile/src/presentation/view/screen/profile_edit_screen.dart';
import 'package:profile/src/presentation/view/screen/delete_profile_screen.dart';

part 'profile_routes.g.dart';

@TypedGoRoute<OnboardingRoute>(
  path: '/onboarding/:profileId',
  name: 'ONBOARDING',
)
class OnboardingRoute extends AuthGuardedRouteData with $OnboardingRoute {
  final String profileId;
  final OnboardingIntent intent;
  const OnboardingRoute({
    required this.profileId,
    this.intent = OnboardingIntent.firstSignIn,
  });
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      OnboardingWizardScreen(profileId: profileId, intent: intent);
}

@TypedGoRoute<ProfileRoute>(path: '/profile/:profileId', name: 'PROFILE')
class ProfileRoute extends AuthGuardedRouteData with $ProfileRoute {
  final String profileId;

  const ProfileRoute({required this.profileId});

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ProfileScreen(profileId: profileId);
}

@TypedGoRoute<ProfileEditRoute>(path: '/editProfile', name: 'EDIT_PROFILE')
class ProfileEditRoute extends AuthGuardedRouteData with $ProfileEditRoute {
  final String profileId;

  const ProfileEditRoute({required this.profileId});
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ProfileEditScreen(profileId: profileId);
}

// Not guarded: deleting the account signs the user out while the completion screen shows, and the screen handles reauth itself.
@TypedGoRoute<ProfileDeleteRoute>(
  path: '/deleteProfile',
  name: 'DELETE_PROFILE',
)
class ProfileDeleteRoute extends GoRouteData with $ProfileDeleteRoute {
  final String profileId;
  const ProfileDeleteRoute({required this.profileId});
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DeleteProfileScreen(profileId: profileId);
}

@TypedGoRoute<ProfileSettingsRoute>(
  path: '/profileSettings/:profileId',
  name: 'PROFILE_SETTINGS',
)
class ProfileSettingsRoute extends AuthGuardedRouteData with $ProfileSettingsRoute {
  final String profileId;
  const ProfileSettingsRoute({required this.profileId});
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ProfileSettingsScreen(
        profileId: profileId,
        clearCacheCapability: GetIt.I.get<ClearCacheCapability>(),
      );
}

/// Will be used to register the profile module's routes with the app's router.
final List<RouteBase> $profileRoutes = [
  $onboardingRoute,
  $profileRoute,
  $profileEditRoute,
  $profileDeleteRoute,
  $profileSettingsRoute,
];
