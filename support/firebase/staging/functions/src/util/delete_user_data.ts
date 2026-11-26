import {Firestore} from "firebase-admin/firestore";
import {Bucket} from "@google-cloud/storage";

/**
 * Deletes everything stored for a user; safe to repeat.
 * @param {Firestore} db Firestore instance.
 * @param {Bucket} bucket Default Storage bucket.
 * @param {string} uid The deleted user's ID.
 * @return {Promise<void>} Resolves when all data is gone.
 */
export async function deleteUserData(
  db: Firestore,
  bucket: Bucket,
  uid: string,
): Promise<void> {
  // recursiveDelete also removes sessions and statsAudit subcollections.
  await Promise.all([
    db.recursiveDelete(db.doc(`profiles/${uid}`)),
    db.doc(`presence/${uid}`).delete(),
    bucket.deleteFiles({prefix: `profiles/${uid}/`}),
  ]);
}
