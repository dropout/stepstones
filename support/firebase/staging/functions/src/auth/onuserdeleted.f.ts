// v2 has no Auth deletion trigger, so this uses v1.
import {region} from "firebase-functions/v1";
import {getFirestore} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {logger} from "firebase-functions";
import {deleteUserData} from "../util/delete_user_data";

/**
 * Deploy as `auth-onuserdeleted`.
 * Removes a user's data whenever their Auth account is deleted,
 * whether from the app, the console or the Admin SDK.
 */
export default region("europe-west3")
  .runWith({failurePolicy: true})
  .auth.user()
  .onDelete(async (user) => {
    await deleteUserData(getFirestore(), getStorage().bucket(), user.uid);
    logger.info("Deleted user data", {uid: user.uid});
  });
