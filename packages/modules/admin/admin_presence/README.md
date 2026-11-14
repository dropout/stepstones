# admin_presence

Live overview of who started practicing recently, for the Stepstones admin app.

The module listens to the same `presence/{profileId}` Firestore documents the `social` module writes. Each profile has one document that is overwritten at every practice start, so an entry means "last started at", not "still practicing".
It keeps its own tolerant, read-only model of that schema so the admin app does not depend on `social`; keep `data/mapper/admin_presence_mapper.dart` in sync with `PresenceEntity` there.

The listener is capped at `AdminPresenceCubit.limit` documents and the time window is re-applied client-side every minute, so entries age out without re-querying.
