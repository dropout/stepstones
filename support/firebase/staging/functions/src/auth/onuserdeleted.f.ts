import {onUserDeleted} from "firebase-functions/v2/identity";
import {getFirestore} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {logger} from "firebase-functions";
import {deleteUserData} from "../util/delete_user_data";

/**
 * Deploy as `auth-onuserdeleted`.
 * Removes a user's data whenever their Auth account is deleted,
 * whether from the app, the console or the Admin SDK.
 */
export default onUserDeleted({retry: true}, async (event) => {
  const uid = event.data.uid;
  await deleteUserData(getFirestore(), getStorage().bucket(), uid);
  logger.info("Deleted user data", {uid});
});
