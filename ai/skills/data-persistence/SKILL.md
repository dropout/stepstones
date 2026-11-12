---
name: data-persistence
description: "Implement persistence in a Stepstones module's data layer: DataProvider interfaces and Firebase/Drift/Storage implementations, repository implementations of domain repository interfaces, freezed/JSON serialization, preferCache and stream behavior, and DocumentNotFoundException handling. Use when adding or changing a data provider, a repository implementation, Firestore queries, Drift table access, or stored entity shape."
license: MIT
---

# Stepstones Data Persistence

Read `data-layer` first for folder map and rules. This skill covers `data/datasource/` and `data/repository/`.

## Pattern: provider + repository

```text
domain/repository/XRepository          (interface, entities)
        ^ implements
data/repository/DefaultXRepository     (thin; delegates to provider)
        v uses
data/datasource/XDataProvider          (interface, module-private)
        ^ implements
data/datasource/FirebaseXDataProvider  (Firestore + converter)
```

Reference: `profile` (`profile_data_provider.dart`, `firebase_profile_data_provider.dart`, `default_profile_repository.dart`).

### DataProvider interface

- `abstract interface class XDataProvider implements DataProvider<XEntity>` from core (`create/read/readStream/update/delete/exists`), plus only the module-specific queries (`query({int limit})`, `queryStream`, `queryAll({bool preferCache})`).
- Module-private: never exported through the barrel.
- Providers return entities. They never return `DocumentSnapshot`, Drift rows, or public models.

### Firebase provider

- `class FirebaseXDataProvider extends FirebaseDataProvider<XEntity> implements XDataProvider`.
- Pass the typed collection to `super` with the converter:

```dart
FirebaseProfileDataProvider(FirebaseFirestore fireStore) : super(
  fireStore.collection('profiles').withConverter<ProfileEntity>(
    fromFirestore: (snapshot, _) => fromFireStore(snapshot, ProfileEntity.fromJson),
    toFirestore: (profile, _) => profile.toFireStore(),
  ),
);
```

- Queries are built in a private `_buildQuery(...)` on `collectionRef` and executed with `buildListFromQuery(query, preferCache: ...)` / `buildStreamFromQuery(query)`.
- Sub-collections: take the parent id as a constructor parameter (`FirebaseTimerSettingsHistoryDataProvider(fireStore, profileId)`).
- Entity must `implements SerializableEntity` (core) so `toFireStore()` is available.
- Missing documents throw `DocumentNotFoundException` (core). Catch it only where "not found" has business meaning (create-or-update flows).
- `preferCache: true` reads the Firestore cache first; `filterCached: true` on streams drops cache-only snapshots. Pass them through unchanged from repository to provider.

### Serialization

- Entities are serialized by freezed/json_serializable: `fromJson` factory, `@JsonSerializable(explicitToJson: true)`, converters from core (`@DateTimeConverter()`, `DurationConverter`, ...). No hand-written DTO unless the stored shape differs from the entity.
- When a field is renamed or added, check the Firebase functions in `support/firebase/` that write the same documents. Some records are created server-side.
- Storage-specific fields are added or converted at the write site with a one-line why. `FirebaseStatsAuditRepository` converts the entity's `expireAt` to a Firestore `Timestamp` for TTL, rather than storing its JSON integer.

### Repository implementation

- Standard case: `class DefaultXRepository extends CrudRepositoryOps<XEntity> implements XRepository`, constructor `required this.xDataProvider` with `: super(xDataProvider)`. Add only the query delegations the interface declares.
- Logic beyond delegation (create-or-increment, batching, merging local and remote) is allowed in a repository only when it is about **storage mechanics**. Business rules go to the domain (service/use case).
- Repositories receive providers through the constructor, never construct them inside methods.
- Intentional exception: `FirebaseStatsAuditRepository` writes a single-purpose audit batch directly to Firestore behind the domain repository interface. The standard CRUD provider would add unused operations; introduce a narrow provider if reuse or independent substitution becomes necessary.

### Drift (local database)

- Table and database live in `src/drift/`. A `DriftXDataProvider implements XDataProvider` wraps queries; its interface is module-private.
- Row classes are data-layer types. Convert with mapper extensions (`toDomain()` / `toRow()`, see `data-boundary`) before returning from the repository.
- Use `clock.now()`, not `DateTime.now()`.

### Storage (Firebase Storage)

- Use core's `StorageDataProvider` (`uploadFile`, `downloadFile`, `getDownloadURL`, `deleteFile`, `deleteFolder`) and `StorageRepository`. Do not call `FirebaseStorage` directly.

### Faker extensions

`datasource/faker_*_extension.dart` builds fixtures for tests and Widgetbook (`extension on Faker`). Update them when an entity or public model gains a required field.

## DI

```dart
registerLazySingleton<ProfileDataProvider>(
  () => FirebaseProfileDataProvider(GetIt.I.get<FirebaseProvider>().firestore),
);
registerLazySingleton<ProfileRepository>(
  () => DefaultProfileRepository(profileDataProvider: GetIt.I.get<ProfileDataProvider>()),
);
```

Providers whose path depends on runtime data (profile id) are created by an injected factory registered in DI. `DefaultTimerSettingsHistoryRepository` creates a provider for the requested profile on each call.

## Testing

- Repository: mock the provider interface; assert delegation and the create-or-update branches.
- Provider: use the emulator configuration in `packages/firebase_provider/`; do not mock `Query`.
- Serialization: round-trip `toJson` / `fromJson` for every stored entity.


## Checklist

- [ ] Provider returns entities only; query built via `_buildQuery`.
- [ ] Entity implements `SerializableEntity`; JSON round-trip tested.
- [ ] Repository uses an injected provider in the standard case and is registered by interface type; document intentional exceptions.
- [ ] No SDK or Drift type crosses the repository boundary.
- [ ] Server-written fields checked against `support/firebase/`.
