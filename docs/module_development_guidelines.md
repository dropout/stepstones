# Module Development Guidelines

This guide describes how to structure, implement, and integrate feature modules in the Stepstones workspace. For the current module graph and cross-module dependency rules, see the [module dependency guidelines](./module_dependency_guidelines.md).

## Goals

- Keep each feature cohesive, with clear responsibilities and a small public surface.
- Separate UI, business rules, and data access.
- Use the smallest structure that fits the feature; not every module needs every layer, route, or use case.

## Layers

- **Domain:** Feature entities, repository and service contracts, and business rules. Use cases express meaningful operations or orchestration; a Cubit may use a repository contract directly for simple CRUD.
- **Data:** Data providers, repository implementations, platform integrations, and mappers. Data implementations fulfill domain contracts.
- **Presentation:** Screens and widgets render state and dispatch user actions. Cubits or Blocs coordinate flows and emit immutable state.
- **Public API:** Contracts, public models, reusable views, and selected view models intended for other packages. Export the intended surface from the package barrel.

Presentation depends on domain contracts; data implements domain contracts. Keep business logic and data access out of widgets.

## Package structure

Feature modules are workspace packages under `packages/modules/`. Practice modules are under `packages/modules/practice/`. Use an existing package such as `packages/modules/profile` as a reference and create only the files and folders needed.

```text
packages/modules/<feature>/
  pubspec.yaml
  analysis_options.yaml
  l10n.yaml                         # when localized UI is present
  lib/
    <feature>.dart                  # public barrel
    l10n/
      <feature>_en.arb
      <feature>_hu.arb
      <feature>_localizations.dart  # generated
    src/
      <feature>_di.dart
      <feature>_routes.dart         # when the module owns routes
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

`src/public/` identifies candidates for cross-module use; only items exported by `lib/<feature>.dart` are part of the public package API. Internal domain, data, and presentation files are not cross-module APIs. Do not hand-edit `*.g.dart`, `*.freezed.dart`, generated routes, or generated localizations.

## Public API and module relationships

Export only the contracts, public models, reusable views, view models, routes, localization delegates, and registration functions that consumers need. Map internal entities and persistence models to public models when data crosses a package boundary.

Modules can depend on other modules through their public barrels, including deliberately exported UI. Check the existing dependency graph and avoid circular dependencies before adding a package dependency. See the [module dependency guidelines](./module_dependency_guidelines.md) for the rules and current relationships.

## Dependency injection and routing

- Keep module registrations in `lib/src/<feature>_di.dart` and export the registration function through the barrel.
- Prefer constructor injection; register dependencies with lifetimes appropriate to their use. Cubits bound to a screen commonly use factories.
- Keep business logic out of DI files. The mobile app registers modules in `apps/mobile_app/lib/bootstrap/app_di.dart`.
- Define routes in `lib/src/<feature>_routes.dart` only when the module owns routes. Add them to the app router in `apps/mobile_app/lib/bootstrap/initializer.dart`.
- Add the module's localization delegate to `apps/mobile_app/lib/app.dart` when it has generated localizations.

## State, errors, and localization

- Use Cubit for straightforward state flows and Bloc when event-driven coordination is useful.
- Keep states focused and immutable, with explicit loading and failure states where needed.
- Handle errors where they can be reported or presented; use the project's logging and Crashlytics services where appropriate.
- Put user-facing text in `lib/l10n/<feature>_en.arb` and `<feature>_hu.arb`. Configure package-root `l10n.yaml`, translate both locales, and regenerate localizations after changes.
- Reuse existing package or core strings where appropriate and use ICU syntax for plural or select messages.

## Testing and verification

Test meaningful domain rules, data mapping and repository behavior, Cubit transitions, public APIs, and important widget behavior. Add integration tests for flows whose important behavior spans packages or platform services.

From the package directory:

```bash
dart format --line-length 120 lib test
flutter analyze
flutter test
```

From the workspace root, run the boundary check with the actual module path:

```bash
bash support/maintenance_scripts/check_module_boundaries.sh packages/modules/<feature>
```

For practice modules, use `packages/modules/practice/<feature>`. Regenerate changed generated sources rather than editing them:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

Run these commands in the package when applicable. When a public API, package barrel, or core contract changes, also analyze affected dependents and `apps/mobile_app`. See [verify-package](../ai/skills/verify-package/SKILL.md) for details.

## Adding a module to the workspace

- [ ] Confirm the feature boundary and its place in the dependency graph; avoid cycles.
- [ ] Create the package and add its path to the root `pubspec.yaml` workspace.
- [ ] Create its public barrel and add the package dependency to `apps/mobile_app/pubspec.yaml` if the app uses it.
- [ ] Register dependencies in `apps/mobile_app/lib/bootstrap/app_di.dart` when the app composes the module.
- [ ] Add routes and a localization delegate to the app when applicable.
- [ ] Add Widgetbook integration if its UI should be documented there.
- [ ] Update the module inventory in `AGENTS.md`.
- [ ] Generate code as needed, then format, analyze, test, and check boundaries.
