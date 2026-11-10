# Profile module

The Profile module manages user profiles and settings, displays profile
statistics, and provides profile-related screens and reusable widgets.

## Features

- Load and observe profile data, including profile images and settings.
- Create and edit profiles and delete profiles with their associated account
  data.
- Track session statistics, milestones, and consecutive practice days.
- Display profile summaries and detailed statistics.
- Provide profile settings, image, and navigation widgets.
- Support English and Hungarian UI localization.

## Integration

This is a workspace package for the Stepstones Flutter app. Add
`$profileRoutes` to the app's router configuration:

```dart
final router = GoRouter(
  routes: [
    ...$profileRoutes,
    ...otherRoutes,
  ],
);
```

Register the app's `GoRouter` and `FirebaseProvider` with GetIt, then register
core dependencies and the Auth module before the Profile module. Profile
registration also requires the core storage and image-safety services:

```dart
GetIt.I.registerSingleton<GoRouter>(router);
GetIt.I.registerSingleton<FirebaseProvider>(firebaseProvider);

await GetIt.I.registerCoreDependencies();
GetIt.I.registerAuthModuleDependencies();
GetIt.I.registerProfileModuleDependencies();
```

The app should provide a shared `ProfileCubit` where profile widgets or screens
need it. See the [mobile app bootstrap](../../../apps/mobile_app/lib/bootstrap/initializer.dart)
and [dependency registration](../../../apps/mobile_app/lib/bootstrap/app_di.dart)
for the current setup.

## Usage

Use the shared `ProfileNavigator` through app services to open profile screens;
avoid navigating to profile routes directly:

```dart
await context.services.profileNavigator.navigateToProfile(profileId);
await context.services.profileNavigator.navigateToProfileEdit(profileId);
await context.services.profileNavigator.navigateToProfileSettings(profileId);
```

The navigator also provides `navigateToProfileWizard` and
`navigateToProfileDelete`. Each method accepts an optional `NavigationType`
(`push`, `replace`, or `go`).

To access profile data from another module, use the public API:

```dart
import 'package:get_it/get_it.dart';
import 'package:profile/profile.dart';

final profile = await GetIt.I<ProfilePublicApi>().getProfile(profileId);
print(profile.displayName);
```

`ProfilePublicApi` also exposes `getProfileStream` and
`updateProfileStatsWithSession`. The module exports public profile models,
statistics widgets, and reusable widgets such as `ProfileButton` and
`ProfileAvatar`.
