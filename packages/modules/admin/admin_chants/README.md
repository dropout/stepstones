# admin_chants

Chant catalog management for the Stepstones admin app: list, rename, reorder and upload chants, and replace their audio, lyrics or cover.

The module reads and writes the same `chants/{id}` Firestore documents the `chanting` module consumes. The document shape, asset file names and Storage paths come from the shared `chant_schema` package, so the two cannot drift apart.
Reading stays tolerant of malformed documents so they remain visible and fixable; each chant is also run through the shared model's parser to flag the ones the mobile app cannot load.
Writes touch single fields only, because `playCount` is server-maintained and protected by the security rules.

Uploads go to `chants/{id}/chant.mp3|chant.ass|cover.jpg` in Storage before the document is written, so clients never see a chant without files. Replacing an asset increments its version in `metaData`, which is what makes the mobile cache re-download it.
