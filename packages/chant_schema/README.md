# chant_schema

The single definition of the chant catalog's backend shape, shared by the mobile `chanting` module (reads) and the admin `admin_chants` module (writes).

- `ChantEntity` and `ChantMetaDataEntity`: the `chants/{id}` Firestore document.
- `ChantAssetType`: the three files of a chant, their names, Storage paths and `metaData` field names.

Change the schema here only; a field the mobile app requires must also be written by the admin app, and both pick it up from this package.
