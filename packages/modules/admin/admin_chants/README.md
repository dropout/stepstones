# admin_chants

Chant catalog management for the Stepstones admin app: list, rename, reorder and upload chants, and replace their audio, lyrics or cover.

The module reads and writes the same `chants/{id}` Firestore documents the `chanting` module consumes. It keeps its own tolerant model of that schema so the admin app does not depend on playback and caching code; keep `data/mapper/admin_chant_mapper.dart` in sync with `ChantEntity` in `chanting`.
Writes touch single fields only, because `playCount` is server-maintained and protected by the security rules.

Uploads go to `chants/{id}/chant.mp3|chant.ass|cover.jpg` in Storage before the document is written, so clients never see a chant without files. Replacing an asset increments its version in `metaData`, which is what makes the mobile cache re-download it.
