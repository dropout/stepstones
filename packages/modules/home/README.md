# Home module

The Home module provides Stepstones' main screen for choosing and starting a
meditation session. It brings together the sitting timer and chanting settings
views, and provides the app bar and session-mode controls.

## Features

- Home screen at `/` with a date header and profile button.
- Switch between sitting and chanting settings when signed in.
- Persist the selected session mode using `HydratedBloc`.
- Use sitting mode while signed out.
- Provide a `HomeNavigator` implementation for returning to the home route.

## Integration

This is a workspace package for the Stepstones Flutter app. Register core
dependencies and make the app's `GoRouter` available from GetIt before
registering the Home module:

```dart
GetIt.I.registerSingleton<GoRouter>(router);
await GetIt.I.registerCoreDependencies();
GetIt.I.registerHomeModuleDependencies();
```

Include `$homeRoutes` in the app router's routes list. The Home module defines
the `/` route:

```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    ...$homeRoutes,
    ...otherRoutes,
  ],
);
```

In the app, register the router and module dependencies alongside the other
workspace modules. `HomeScreen` expects the app's shared
`AuthStateCubit` and `ProfileCubit` in the widget tree, as well as the
dependencies for the timer and chanting settings views. See the [mobile app
bootstrap](../../../apps/mobile_app/lib/bootstrap/initializer.dart) and
[dependency registration](../../../apps/mobile_app/lib/bootstrap/app_di.dart)
for the current setup.

## Usage

Navigate to the home screen through the shared `HomeNavigator`, rather than
using the route directly:

```dart
context.services.homeNavigator.navigateToHome(type: .go);
```

`navigateToHome` accepts an optional `refresh` value to recreate the home
screen after settings changes, and a `NavigationType` (`push`, `replace`, or
`go`) to choose how navigation is performed. The Home module registers the
`HomeNavigator` implementation as a GetIt singleton; the app exposes it through
`Services`.

The `HomeScreen` widget is also exported for cases where the screen must be
embedded directly and its required dependencies and shared cubits are available:

```dart
import 'package:home/home.dart';

const HomeScreen();
```

`HomeScreenCubit` stores a `HomeScreenState` with a `sessionType`. The available
values are `HomeScreenViewState.sitting` and `HomeScreenViewState.chanting`;
call `setSessionType` to change the selection. The Home screen itself selects
the sitting view when the user is signed out.

