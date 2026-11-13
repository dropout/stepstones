# Commands for running and building
This is a list of useful commands for the project.

## Available flavors for commands `<flavor>`
When running commands that require a flavor, ask for clarification.
- `development`
- `qa`
- `staging`
- `production`

## Available build modes `<build_mode>`
If no build mode specified, use `debug`.
- `debug`
- `profile`
- `release`

## Running
- Install dependencies: `flutter pub get`
- Generate localizations: `flutter gen-l10n`
- Generate code: `dart run build_runner build`
    - If build_runner reports conflicts, resolve with `dart run build_runner build --delete-conflicting-outputs`.
- Watch for code changes and generate code: `pub run build_runner watch`
- Static checks: `flutter analyze`
- Module boundary checks: `bash support/maintenance_scripts/check_module_boundaries.sh`
- Run: `flutter run --flavor <flavor> -t lib/main_<flavor>.dart --<build_mode>`
- Widget and Unit Tests: `flutter test`
    - Run with `--coverage` for getting test coverage report.
- Staging Cloud Functions tests: `npm --prefix support/firebase/staging/functions test`
- Staging Cloud Functions lint: `npm --prefix support/firebase/staging/functions run lint`
- Staging security rules tests (Firestore and Storage emulators): `npm --prefix support/firebase/staging/rules_test test`
    - First run needs `npm --prefix support/firebase/staging/rules_test install`.
- Grant or revoke the admin claim (run from `support/maintenance_scripts`): `node src/set_admin_claim.mjs --project=<firebase-project-id> (--email=<email>|--uid=<uid>) [--revoke] (--confirm|--dry-run)`
- Integration Tests: `flutter test integration_test/<test_file>.dart --flavor <flavor> --dart-define=IS_TEST=true --dart-define=TEST_USER_EMAIL=<email> --dart-define=TEST_USER_PASSWORD=<password>`
- Format: `dart format .`
- Clean: `flutter clean`

## Admin app (macOS)
Run from `apps/admin_app`. The app is signed with the development team because Firebase Auth needs keychain access.
- Run against local emulators (no config file needed): `flutter run -d macos -t lib/main_dev.dart`
    - Start the emulators first from `support/firebase/staging`: `firebase emulators:start --only auth,firestore,storage --project demo-stepstones`
- Run against a Firebase project: `flutter run -d macos -t lib/main_<flavor>.dart --dart-define-from-file=config/<flavor>.json`
    - Copy `config/example.json` to `config/<flavor>.json` and fill it from the admin app's Firebase registration; these files are git-ignored.
- Integration test (from `support/firebase/staging`): `firebase emulators:exec --only auth,firestore,storage --project demo-stepstones "cd ../../../apps/admin_app && flutter test integration_test/admin_access_test.dart -d macos"`

## Building
- If build mode is not excplicitly specified use `debug` build mode.
- App Bundle (Android): `flutter build appbundle --flavor <flavor> -t lib/main_<flavor>.dart --<build_mode>`
- IPA (iOS): `build ipa --flavor <flavor> -t lib/main_<flavor>.dart --<build_mode>`

## Distribution
- iOS to Firebase App Distribution (`ios_testers`) + Crashlytics symbols: `bash support/maintenance_scripts/distribute_ios.sh <flavor> [--notes "<text>"] [--dry-run]`
    - Example: `bash support/maintenance_scripts/distribute_ios.sh staging`
    - Firebase project and app id are read from `apps/mobile_app/ios/config/<flavor>/GoogleService-Info.plist`; `FIREBASE_IOS_APP_ID` overrides the app id.
    - Requires a clean git tree; bumps only the build number in `apps/mobile_app/pubspec.yaml` and commits it after success.
- Android to Firebase App Distribution (`android_testers`) + Crashlytics symbols: `bash support/maintenance_scripts/distribute_android.sh <dev|qa|staging|prod> [--notes "<text>"] [--dry-run]`
    - Example: `bash support/maintenance_scripts/distribute_android.sh staging`
    - Firebase project and app id are read from `apps/mobile_app/android/app/src/<flavor>/google-services.json`; `FIREBASE_ANDROID_APP_ID` overrides the app id.
    - Requires a clean git tree; bumps only the build number in `apps/mobile_app/pubspec.yaml` and commits it after success.
