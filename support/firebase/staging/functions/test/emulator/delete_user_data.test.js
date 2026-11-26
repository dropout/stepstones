/* eslint-disable @typescript-eslint/no-require-imports */
// Runs against the Firestore and Storage emulators: npm run test:emulator.
const {test} = require("node:test");
const assert = require("node:assert/strict");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {deleteUserData} = require("../../lib/util/delete_user_data");

const projectId = "demo-stepstones-functions";
initializeApp({projectId, storageBucket: `${projectId}.appspot.com`});
const db = getFirestore();
const bucket = getStorage().bucket();

/**
 * Seeds a profile with every kind of user data.
 * @param {string} uid User ID.
 */
async function seed(uid) {
  await db.doc(`profiles/${uid}`).set({id: uid});
  await db.doc(`profiles/${uid}/sessions/s1`).set({id: "s1"});
  await db.doc(`profiles/${uid}/statsAudit/a1`).set({id: "a1"});
  await db.doc(`presence/${uid}`).set({id: uid});
  await bucket.file(`profiles/${uid}/photo.jpg`).save("img");
}

test("deletes all of a user's data and leaves others alone", async () => {
  await seed("alice");
  await seed("bob");

  await deleteUserData(db, bucket, "alice");

  for (const path of ["profiles/alice", "profiles/alice/sessions/s1",
    "profiles/alice/statsAudit/a1", "presence/alice"]) {
    assert.equal((await db.doc(path).get()).exists, false, path);
  }
  const [aliceFiles] = await bucket.getFiles({prefix: "profiles/alice/"});
  assert.equal(aliceFiles.length, 0);

  assert.equal((await db.doc("profiles/bob/sessions/s1").get()).exists, true);
  assert.equal((await db.doc("presence/bob").get()).exists, true);
  const [bobFiles] = await bucket.getFiles({prefix: "profiles/bob/"});
  assert.equal(bobFiles.length, 1);
});

test("is safe to repeat when nothing is left", async () => {
  await deleteUserData(db, bucket, "nobody");
  await deleteUserData(db, bucket, "nobody");
});
