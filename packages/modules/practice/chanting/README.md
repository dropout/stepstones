# Chanting

The chanting module prepares a playlist of chants, plays their audio, and
displays synchronized lyrics. It also reports completed chanting sessions and
can publish presence when the user's settings allow it.

## Integration

Import `package:chanting/chanting.dart` for the module's public API, models,
settings UI, routes, and dependency registration. Other modules should use
this barrel rather than importing chanting implementation files.

`ChantingPublicApi` provides:

- `loadChants(preferCache: ...)` and `chantsStream` for the chant catalogue.
- `clearCachedChants()` to remove locally cached chant files.

The settings view builds a `ChantingSettings` playlist and opens
`ChantingRoute` with those settings as `$extra`. The app adds
`$chantingRoutes` to its router and calls
`GetIt.I.registerChantingModuleDependencies()` during bootstrap.

The mobile app initializes SoLoud and its `AppAudioHandler` before resolving
chanting services. It also registers the Firebase, auth, profile, social,
session, and core dependencies used by the module. See
[`initializer.dart`](../../../../apps/mobile_app/lib/bootstrap/initializer.dart)
and [`app_di.dart`](../../../../apps/mobile_app/lib/bootstrap/app_di.dart) for
the application wiring.

## Playback and caching

At session start, the module fetches the chant catalogue, validates cached
audio and lyrics against the current metadata, and downloads invalid assets.
Validation checks the cache entry's validity and version, file existence, and
the expected hash and size when provided. Downloaded assets are validated
before they are marked complete.

Cache work is deduplicated by chant ID, but the prepared resources preserve
playlist order and repeated entries. Progress is streamed to the player; a
failed preparation or audio setup produces the existing player error state
and is recorded for diagnostics. Cache files live under `chant_cache` in the
app's documents directory. Clearing the cache removes those files; Drift
metadata entries remain and are checked against the filesystem on reuse.

Once prepared, the audio handler starts the playlist and the player loads the
current chant's lyrics. A newer track selection supersedes pending lyrics
requests so an older result cannot replace the current track's lyrics.

## Architecture

- `src/domain/` contains domain models, cache and audio contracts, and use
  cases for preparing, playing, and completing a session.
- `src/data/` implements those contracts, including Firebase catalogue and
  storage access, Drift cache metadata, filesystem operations, audio
  adaptation, and lyrics parsing.
- `src/presentation/` owns the private player state and views.
- `src/public/` and `chanting.dart` define the module-facing surface. Public
  playlist items are mapped to domain items for player state.
- `src/audio/` contains the SoLoud handler used by the app's audio service.

The central flow is view → cubit → use case or service → data layer. The
Widgetbook app has a documented exception for previews of internal widgets;
those previews are not a supported public API.

## Development

Use the workspace setup in [`AGENTS.md`](../../../../AGENTS.md) and the run
and build instructions in [`docs/commands.md`](../../../../docs/commands.md).
Running the mobile app also requires the Firebase configuration files for the
chosen flavor, as described in the workspace setup guide.

From this package directory:

```sh
dart run build_runner build
flutter analyze
flutter test
```

Run code generation after changing generated models, routes, or other
builder inputs. For a focused test, pass its path to `flutter test`, for
example `flutter test test/presentation/viewmodel/chanting_cubit_test.dart`.
From the repository root, check module boundaries with:

```sh
bash support/maintenance_scripts/check_module_boundaries.sh packages/modules/practice/chanting
```
