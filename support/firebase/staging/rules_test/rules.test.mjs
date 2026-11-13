import {after, before, beforeEach, test} from "node:test";
import {readFileSync} from "node:fs";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from "firebase/firestore";
import {getBytes, ref, uploadBytes} from "firebase/storage";

const rulesDir = new URL("../", import.meta.url);
const chant = {id: "heart-sutra", name: "Heart Sutra", order: 0};
const bytes = new Uint8Array([1, 2, 3]);

let env;
let anonymous;
let user;
let admin;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-stepstones-rules",
    firestore: {
      rules: readFileSync(new URL("firestore.rules", rulesDir), "utf8"),
    },
    storage: {
      rules: readFileSync(new URL("storage.rules", rulesDir), "utf8"),
    },
  });
  anonymous = env.unauthenticatedContext();
  user = env.authenticatedContext("user-1");
  admin = env.authenticatedContext("admin-1", {admin: true});
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "chants/seeded"),
      {id: "seeded", name: "Seeded", order: 1, playCount: 5});
    await setDoc(doc(db, "global_stats/all_time/shards/0"),
      {totalSessions: 3});
    await uploadBytes(ref(context.storage(), "chants/seeded/chant.mp3"),
      bytes);
  });
});

after(async () => {
  await env.cleanup();
});

test("chants are readable by signed-in users only", async () => {
  await assertSucceeds(getDoc(doc(user.firestore(), "chants/seeded")));
  await assertFails(getDoc(doc(anonymous.firestore(), "chants/seeded")));
});

test("only admins can create, update and delete chants", async () => {
  const path = `chants/${chant.id}`;
  await assertFails(setDoc(doc(user.firestore(), path), chant));
  await assertFails(
    updateDoc(doc(user.firestore(), "chants/seeded"), {name: "Hacked"}));
  await assertFails(deleteDoc(doc(user.firestore(), "chants/seeded")));

  await assertSucceeds(setDoc(doc(admin.firestore(), path), chant));
  await assertSucceeds(
    updateDoc(doc(admin.firestore(), "chants/seeded"), {name: "Renamed"}));
  await assertSucceeds(deleteDoc(doc(admin.firestore(), "chants/seeded")));
});

test("a false or missing admin claim grants nothing", async () => {
  const notAdmin = env.authenticatedContext("user-2", {admin: false});
  await assertFails(
    setDoc(doc(notAdmin.firestore(), `chants/${chant.id}`), chant));
});

test("admin chant writes cannot touch playCount or mismatch the id",
  async () => {
    const db = admin.firestore();
    await assertFails(
      setDoc(doc(db, `chants/${chant.id}`), {...chant, playCount: 10}));
    await assertFails(updateDoc(doc(db, "chants/seeded"), {playCount: 99}));
    await assertFails(
      setDoc(doc(db, "chants/other-id"), chant));
    await assertFails(updateDoc(doc(db, "chants/seeded"), {id: "renamed"}));
  });

test("global stats are admin read-only", async () => {
  const path = "global_stats/all_time/shards/0";
  await assertSucceeds(getDoc(doc(admin.firestore(), path)));
  await assertFails(getDoc(doc(user.firestore(), path)));
  await assertFails(setDoc(doc(admin.firestore(), path), {totalSessions: 0}));
});

test("the admin claim does not open other users' profiles", async () => {
  await assertFails(getDoc(doc(admin.firestore(), "profiles/user-1")));
  await assertSucceeds(getDoc(doc(user.firestore(), "profiles/user-1")));
});

test("chant assets are readable by users, writable by admins", async () => {
  const path = "chants/seeded/chant.mp3";
  await assertSucceeds(getBytes(ref(user.storage(), path)));
  await assertFails(getBytes(ref(anonymous.storage(), path)));
  await assertFails(uploadBytes(ref(user.storage(), path), bytes));
  await assertSucceeds(uploadBytes(ref(admin.storage(), path), bytes));
});

test("profile storage stays owner-writable", async () => {
  const path = "profiles/user-1/photo.jpg";
  await assertSucceeds(uploadBytes(ref(user.storage(), path), bytes));
  await assertFails(uploadBytes(ref(admin.storage(), path), bytes));
});
