# Module Guidelines

This guide describes how to structure, integrate, and verify feature packages in the Stepstones workspace. Feature packages live under `packages/modules/`; the app shell is `apps/mobile_app/`. For import-boundary details, see [module dependency guidelines](./new_docs/module_dependency_guidelines.md).

## 1. Architecture at a glance

Organize each feature around its responsibilities, not around a mandatory set of classes:

```text
Presentation -> Domain contracts
Data implementations -> Domain contracts
```

- **Presentation** owns feature screens, widgets, and UI state. Cubits/Blocs coordinate user actions and expose immutable state.
- **Domain** owns feature concepts, repository/service contracts, and business rules. Add use cases when they orchestrate work or express meaningful behavior.
- **Data** implements domain contracts using Firebase, local persistence, files, or platform services. Keep provider details and mapping here.
- **Public API** is the supported surface for other packages. It may contain public API contracts, public models, reusable views, and selected view models.

Keep the design pragmatic. A simple read/display flow may call a repository contract directly from a Cubit; do not add a one-line use case solely to satisfy a diagram. Keep UI widgets declarative and avoid putting business logic or persistence calls in them.

## 2. Package structure

New feature modules are Dart workspace packages. Use the existing package nearest in purpose as the starting point, commonly `packages/modules/profile`. Add only folders and files the feature needs.

```text
packages/modules/<feature>/
  pubspec.yaml
  analysis_options.yaml
  l10n.yaml                         # when the package has localized UI
  lib/
    <feature>.dart                  # public barrel
    l10n/
      <feature>_en.arb
      <feature>_hu.arb
      <feature>_localizations.dart  # generated
    src/
      <feature>_di.dart
      <feature>_routes.dart         # only when the package has routes
      domain/
        entity/
        repository/
        port/
        service/
        usecase/
      data/
        datasource/
        repository/
        mapper/
        service/
      presentation/
        view/
        viewmodel/
      public/
        api/
        model/
        view/
        viewmodel/
  test/
```

The layout is a guide, not a requirement to create every directory. Keep generated files generated; do not hand-edit `*.g.dart`, `*.freezed.dart`, generated route files, or generated localization files.

## 3. Dependency and module boundaries

- `core` is foundational and must not depend on feature modules.
- Feature dependencies flow in one direction in the module hierarchy. Do not introduce dependency cycles.
- Depend on another feature only when needed, and only through its package barrel (for example, `import 'package:profile/profile.dart';`).
- Never import or export another package's `src/` files. Do not reach into another package's data or presentation implementation.
- Keep repository interfaces in domain and implementations in data. Data sources are owned by the module that uses them; shared infrastructure belongs in `core`.
- If domain behavior needs another module, define a narrow port in the consuming module's domain and implement it in that module's data layer. Any types in that port must come from stable public package contracts, not another package's internals.
- Do not pass another module's Cubit, screen, or internal widget into a feature. Reusable cross-module UI must be deliberately exported as public API.
- Keep cross-module models at the boundary. Prefer a local view model when a screen needs only a small subset of a foreign public model.

The automated boundary check is the source of truth for enforced import rules. Existing legacy violations may remain; do not add new ones.

## 4. Public package API

The package barrel, `lib/<feature>.dart`, defines the supported import surface.

- Export only contracts, models, widgets/view models, localization delegates, routes, and module registration functions that consumers need.
- Do not export the `domain/`, `data/`, or `presentation/` implementation layers wholesale.
- Keep persistence models and domain entities internal. Map to dedicated public models when data must cross a package boundary.
- Keep APIs small and intentional; changing an exported contract can require updating dependent packages and the app.

Consumers should import the barrel, never a path under `package:<feature>/src/`.

## 5. Dependency injection and routing

- Keep a module's registrations in `lib/src/<feature>_di.dart`, exposed from its barrel.
- Register providers, repositories, services/use cases, and Cubits with lifetimes appropriate to their use. Prefer constructor injection so dependencies are explicit and testable.
- The mobile app is the composition root. Add the package dependency and call its registration function in `apps/mobile_app/lib/bootstrap/app_di.dart` after the modules it depends on.
- Define GoRouter routes close to the feature in `lib/src/<feature>_routes.dart` only when the package owns screens. Export the route list and add it to the router in `apps/mobile_app/lib/bootstrap/initializer.dart`.
- Add a localization delegate to `apps/mobile_app/lib/app.dart` only when the feature has generated localizations.
- Avoid resolving dependencies from GetIt inside feature widgets or domain logic. Use the composition layer to construct objects.

## 6. State, errors, and UI

- Use Cubit for straightforward state flows and Bloc when event-driven coordination provides a clear benefit.
- Keep state focused, immutable, and explicit about meaningful loading, success, and failure cases.
- Keep orchestration in Cubits/use cases/services as appropriate; widgets render state and dispatch user intent.
- Handle errors at a boundary that can report or present them. Use the project's logging and Crashlytics services where appropriate; do not silently turn failures into success-shaped defaults.
- Keep user-facing text localized; do not hardcode it in widgets.

## 7. Localization

For packages with user-facing UI:

- Keep ARB resources in `lib/l10n/<feature>_en.arb` and `lib/l10n/<feature>_hu.arb`.
- Configure package-root `l10n.yaml` with the package ARB directory, generated output file, and a feature-specific `<Feature>Localizations` class.
- Add each key to both locales and provide an actual Hungarian translation.
- Check the package and `core` localizations before adding a duplicate. Use ICU plural/select syntax for variable messages.
- Access strings through the generated localization class (or an established `core` localization extension where appropriate).
- Regenerate after ARB edits with `flutter gen-l10n` in the package, or run `melos run codegen:l10n` from the workspace root.

## 8. Testing and verification

Test behavior at the boundary where it matters; do not add empty tests just to fill a directory.

- **Domain:** test meaningful use cases and services with repository/port fakes or mocks.
- **Data:** test mapping and repository behavior; isolate Firebase or other SDK dependencies behind providers.
- **Presentation:** test Cubit transitions and important widget behavior.
- **Public API:** test exported contracts or behavior where the API adds meaningful translation or orchestration.
- Add integration tests for flows whose important behavior spans packages or platform services.

From the package directory, run:

```bash
dart format --line-length 120 lib test
flutter analyze
flutter test
```

From the workspace root, check module boundaries:

```bash
bash support/maintenance_scripts/check_module_boundaries.sh packages/modules/<feature>
```

If generated sources are stale, regenerate them rather than editing them:

```bash
dart run build_runner build --delete-conflicting-outputs
```

When a public API, package barrel, or core contract changes, also analyze affected dependent packages and `apps/mobile_app`. See [verify-package](../ai/skills/verify-package/SKILL.md) for the full verification workflow.

## 9. Adding a module to the workspace

Before creating a package, confirm that it represents a cohesive feature boundary and decide where it belongs in the dependency hierarchy. Then wire all applicable integration points:

- [ ] Create the package under `packages/modules/` (or `packages/modules/practice/` for a practice submodule).
- [ ] Add it to the root `pubspec.yaml` workspace and configure its package manifest.
- [ ] Create a public barrel; export only the intended API.
- [ ] Add the package to `apps/mobile_app/pubspec.yaml`.
- [ ] Register its dependencies in `apps/mobile_app/lib/bootstrap/app_di.dart` in dependency order.
- [ ] Add routes to the app router if the module owns routes.
- [ ] Add its localization delegate to the app if the module has localizations.
- [ ] Add it to Widgetbook if it exposes UI that should be documented there.
- [ ] Update the module inventory in `AGENTS.md`.
- [ ] Generate code as needed, then format, analyze, test, and run the boundary check.

Not every module needs routes, localization, Widgetbook coverage, or all three layers. Make omissions intentional and keep the package as small as its responsibilities allow.
