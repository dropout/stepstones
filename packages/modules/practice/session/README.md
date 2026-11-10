# Session module

The Session module records completed sitting and chanting sessions. It provides
the completion screen, signed-in session history, persistence, and integrations
with profile statistics.

## Features

- Show a completion screen after a sitting or chanting session.
- Save signed-in users' sessions to Firestore and update their profile and
  statistics.
- Optionally record mindful minutes when platform authorization is available.
- Browse a profile's session history.
- Support English and Hungarian UI localization.

## Integration

This is a workspace package for the Stepstones Flutter app. Add `$sessionRoutes`
to the app's router configuration, alongside the other module routes:

```dart
final router = GoRouter(
  routes: [
    ...$sessionRoutes,
    ...otherRoutes,
  ],
);
```

Register the `GoRouter` and `FirebaseProvider` with GetIt, then register core
dependencies and the Session module:

```dart
GetIt.I.registerSingleton<GoRouter>(router);
GetIt.I.registerSingleton<FirebaseProvider>(firebaseProvider);
await GetIt.I.registerCoreDependencies();
GetIt.I.registerSessionModuleDependencies();
```

The Session module also relies on the profile and stats public APIs, plus
`MindfulMinutesService`; ensure those dependencies are registered before they
are first resolved. See the [mobile app bootstrap](../../../../apps/mobile_app/lib/bootstrap/initializer.dart)
and [dependency registration](../../../../apps/mobile_app/lib/bootstrap/app_di.dart)
for the current setup.

## Usage

Use the shared `SessionNavigator` through app services to open the completion
screen. It creates the session ID and passes the session details to the screen:

```dart
import 'package:core/core.dart';

await context.services.sessionNavigator
    .navigateToSessionCompletedScreen(
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      sessionType: SessionType.timer,
    );
```

For chanting sessions, pass `SessionType.chanting` and set `completedChantIds`
to the IDs of chants completed during that session. The list is stored with the
session record and defaults to empty, so omit it when there are no completed
chants:

```dart
await context.services.sessionNavigator
    .navigateToSessionCompletedScreen(
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      sessionType: SessionType.chanting,
      completedChantIds: completedChantIds,
    );
```

To open a user's history, use the same navigator:

```dart
await context.services.sessionNavigator.navigateToSessionHistory(profileId);
```

`SessionPublicApi.saveSession(profileId, session)` is also available for saving
a session record directly. This persists the record only; it does not run the
completion flow that updates the profile and statistics.
