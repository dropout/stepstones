# admin_access

Sign-in and admin-claim gate for the Stepstones admin app.

Wrap admin-only UI in `AdminAccessGate`; it renders its child only for a signed-in user whose ID token carries the `admin` claim (see `support/maintenance_scripts/src/set_admin_claim.mjs`).
The gate is a convenience, not the security boundary: Firestore and Storage rules enforce the claim.
