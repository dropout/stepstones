# Stats module

The Stats module stores and displays a user's meditation activity over time. It
provides session-statistics APIs and a profile statistics screen with daily,
weekly, monthly, and yearly summaries and charts.

## Features

- Record sitting and chanting session durations and counts.
- Query statistics by date range and granularity.
- Display profile statistics with day, week, month, and year views.
- Support English and Hungarian UI localization.

## Integration

This is a workspace package for the Stepstones Flutter app. Add `$statsRoutes`
to the app's router configuration:

```dart
final router = GoRouter(
  routes: [
    ...$statsRoutes,
    ...otherRoutes,
  ],
);
```

Register the app's `GoRouter` and `FirebaseProvider` with GetIt, then register
core dependencies and the Profile module before the Stats module:

```dart
GetIt.I.registerSingleton<GoRouter>(router);
GetIt.I.registerSingleton<FirebaseProvider>(firebaseProvider);

await GetIt.I.registerCoreDependencies();
GetIt.I.registerProfileModuleDependencies();
GetIt.I.registerStatsModuleDependencies();
```

The Stats module uses Firestore and the Profile public API. The app should
provide a shared `ProfileCubit` for the profile statistics screen. See the
[mobile app bootstrap](../../../apps/mobile_app/lib/bootstrap/initializer.dart)
and [dependency registration](../../../apps/mobile_app/lib/bootstrap/app_di.dart)
for the current setup.

## Usage

Use the shared `StatsNavigator` through app services to open a user's stats
screen rather than navigating to the module route directly:

```dart
await context.services.statsNavigator.navigateToProfileStats(profileId);
```

Other modules can use `StatsPublicApi` to log a session or query aggregated
stats:

```dart
import 'package:get_it/get_it.dart';
import 'package:stats/stats.dart';

final stats = GetIt.I<StatsPublicApi>();

await stats.logSessionStats(
  profileId,
  StatsSession(
    id: sessionId,
    type: StatsSessionType.sitting,
    startTime: startTime,
    endTime: endTime,
    duration: duration,
  ),
);

final buckets = await stats.queryBuckets(
  profileId: profileId,
  from: from,
  to: to,
  granularity: StatsGranularity.weeks,
);
```

Each `StatsBucket` contains the start date, session count, and total minutes
for its day, week, month, or year. The package also exports
`CalculatedStats` for calculating totals and averages from buckets.
