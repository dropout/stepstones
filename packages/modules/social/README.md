# Social module

The Social module lets users see other people who are currently practicing.
It records and queries practice presence and provides the presence screen and
reusable widgets to display nearby or recently active profiles.

## Features

- Record a profile's practice presence with its start time and optional location.
- Query recent presence with paging and optional location-based ordering.
- Display presence in a screen, list, table, or area.
- Support English and Hungarian UI localization.

## Integration

This is a workspace package for the Stepstones Flutter app. Add
`$socialRoutes` to the app's router configuration:

```dart
final router = GoRouter(
  routes: [
    ...$socialRoutes,
    ...otherRoutes,
  ],
);
```

Register the app's `GoRouter` and `FirebaseProvider` with GetIt, then register
core dependencies and the Social module:

```dart
GetIt.I.registerSingleton<GoRouter>(router);
GetIt.I.registerSingleton<FirebaseProvider>(firebaseProvider);

await GetIt.I.registerCoreDependencies();
GetIt.I.registerSocialModuleDependencies();
```

The module uses Firestore to persist and query presence. See the [mobile app
bootstrap](../../../apps/mobile_app/lib/bootstrap/initializer.dart) and
[dependency registration](../../../apps/mobile_app/lib/bootstrap/app_di.dart)
for the current setup.

## Usage

Use the shared `SocialNavigator` through app services to open the presence
screen instead of navigating to the route directly:

```dart
await context.services.socialNavigator.navigateToPresence();
```

Other modules can use `SocialPublicApi` to publish a presence record and
retrieve recent records:

```dart
import 'package:get_it/get_it.dart';
import 'package:social/social.dart';

final social = GetIt.I<SocialPublicApi>();

await social.showPresence(
  profileId: profile.id,
  firstName: profile.firstName,
  lastName: profile.lastName,
  photoBlurhash: profile.photoBlurhash,
  location: profile.location,
  startedAt: DateTime.now(),
);

final presence = await social.queryPresence(
  windowSize: const Duration(hours: 1),
  limit: 20,
  ownProfileId: profile.id,
  location: profile.location,
);
```

Queries default to a three-hour time window and a limit of 20. When a location
is provided, results within the configured `rangeInKm` are ordered by distance;
if there are no location matches, the query falls back to recent presence.
Use `lastDocumentId` to request the next page. Pass `ownProfileId` to exclude
the current user's record.
