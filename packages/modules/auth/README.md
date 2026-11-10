# Auth module

The Auth module provides the Stepstones app's sign-in screens and authentication
services. It uses Firebase Authentication behind a public API, keeping provider
and data-layer details inside the module.

## Features

- Sign in with Google or Apple, or with email and password.
- Sign up with email and password.
- Observe authentication state and retrieve the current user ID.
- Sign out and delete the current account.
- Login screens, routes, and shared authentication state for the app.

## Getting started

This is a workspace package intended for use by the Stepstones Flutter app.
Bootstrap the repository as described in [docs/commands.md](../../../docs/commands.md).
Configure Firebase for each app flavor, including the required platform files
described in [AGENTS.md](../../../AGENTS.md#critical-setup-pitfalls), and enable
the desired authentication providers in Firebase.

During app initialization, register the `FirebaseProvider` and `GoRouter`, then
register core dependencies before the Auth module:

```dart
GetIt.I.registerAuthModuleDependencies();
```

Add the module routes to the app router:

```dart
routes: [
  ...$authRoutes,
  ...appRoutes,
],
```

The routes are `/login` and `/login/email`. The login screens expect the app to
provide the core `AuthStateCubit`; the app resolves its `AuthCubit`
implementation through GetIt. See the [mobile app bootstrap](../../../apps/mobile_app/lib/bootstrap/initializer.dart)
and [dependency registration](../../../apps/mobile_app/lib/bootstrap/app_di.dart)
for the current integration.

## Usage

After dependency registration, use the public API to observe sessions and
initiate authentication:

```dart
import 'package:auth/auth.dart';
import 'package:get_it/get_it.dart';

final auth = GetIt.I<AuthPublicApi>();
final session = await auth.authSessionStream.first;

if (!session.isAuthenticated) {
  final result = await auth.signInWithGoogle();
  print('Signed in ${result.userId}; first sign-in: ${result.isFirstSignin}');
}

await auth.signOut();
```

`AuthSession` contains `isAuthenticated` and a nullable `userId`.
`AuthSigninResult` contains the `userId` and whether this was the user's first
sign-in. Email-based sign-in and sign-up are also available through
`signInWithEmailAndPassword` and `signUpWithEmailAndPassword`.

Sign-in and email account-creation methods expose mapped failures as
`AuthPublicFailure` exceptions. The package exports the failure types and
`toPublicFailure()` mapper for callers that need to inspect them.

## Localization and tests

The module's login UI is localized in English and Hungarian. Source strings are
in `lib/l10n/`; generated localization files should be regenerated rather than
edited directly.

Run the module tests from this directory with:

```sh
flutter test
```
