# Timer module

The Timer module provides configurable sitting meditation sessions, including
the timer settings screen, running timer, audio cues, and settings history.

## Features

- Configure warmup and sitting durations, interval count, and start, interval,
  and end sounds.
- Run a timer with audio playback controls and keep-awake support.
- Persist settings locally and save signed-in users' settings history.
- Support English and Hungarian UI localization.

## Integration

This is a workspace package for the Stepstones Flutter app. Add `$timerRoutes`
to the app's router configuration:

```dart
final router = GoRouter(
  routes: [
    ...$timerRoutes,
    ...otherRoutes,
  ],
);
```

Register the app's `GoRouter`, `FirebaseProvider`, and `AppAudioHandler` with
GetIt, then register core dependencies and the Timer module. The Timer module
depends on the Auth, Profile, Social, and Session modules, which should be
registered before Timer:

```dart
GetIt.I.registerSingleton<GoRouter>(router);
GetIt.I.registerSingleton<FirebaseProvider>(firebaseProvider);
GetIt.I.registerSingleton<AppAudioHandler>(audioHandler);

await GetIt.I.registerCoreDependencies();
GetIt.I.registerAuthModuleDependencies();
GetIt.I.registerProfileModuleDependencies();
GetIt.I.registerSocialModuleDependencies();
GetIt.I.registerSessionModuleDependencies();
GetIt.I.registerTimerModuleDependencies();
```

The app must also provide the `Services` and shared state required by the
settings and timer views. See the [mobile app bootstrap](../../../../apps/mobile_app/lib/bootstrap/initializer.dart)
and [dependency registration](../../../../apps/mobile_app/lib/bootstrap/app_di.dart)
for the current setup.

## Usage

Use the shared `TimerNavigator` through app services to open the timer or a
user's settings history; do not navigate to the module routes directly:

```dart
await context.services.timerNavigator.navigateToTimer();
await context.services.timerNavigator.navigateToTimerSettingsHistory(
  profileId,
);
```

The timer settings UI is available as a widget and can be embedded where the
required app services are provided:

```dart
import 'package:timer/timer.dart';

TimerSettingsView.withCubit();
```

`TimerSettings` contains `warmup`, `duration`, `intervalCount`,
`intervalSound`, `startingSound`, and `endingSound` settings. Its defaults are
a one-minute warmup, ten-minute sitting duration, no interval cues, and the
module's default sounds.

