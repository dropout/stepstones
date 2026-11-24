import 'package:core/core.dart';
import 'package:profile/src/domain/repository/profile_repository.dart';
import 'package:profile/src/domain/service/profile_auth_port.dart';

enum DeleteProfileResult {
	completed,
	/// Firebase needs a recent sign-in before deleting the account.
	authRequired,
	reauthenticationCancelled,
	/// The user confirmed with a different account, so nothing was deleted.
	accountMismatch,
	notSignedIn,
}

class DeleteProfileUseCase with LoggerMixin {
	final ProfileAuthPort authPort;
  final ProfileRepository profileRepository;
  final StorageRepository storageRepository;

	DeleteProfileUseCase({
		required this.authPort,
		required this.profileRepository,
		required this.storageRepository,
	});

	/// Deletes the signed-in user's account and data, confirming their identity first when [reauthenticateWith] is set.
	Future<DeleteProfileResult> execute({ReauthProvider? reauthenticateWith}) async {
		try {
			logger.t('Attempting to delete user account');
      final userId = await authPort.getAuthenticatedUserId();

      // First check if the user is authenticated before proceeding with deletion
      if (userId == null) {
        logger.t('User is not authenticated. Cannot delete profile.');
        return DeleteProfileResult.notSignedIn;
      } else {
        if (reauthenticateWith != null) {
          try {
            await authPort.reauthenticate(reauthenticateWith);
          } on ReauthenticationCancelled {
            return DeleteProfileResult.reauthenticationCancelled;
          } on ReauthenticationAccountMismatch {
            logger.t('Reauthenticated with a different account. Not deleting.');
            return DeleteProfileResult.accountMismatch;
          }
        }


        // Attempt to delete the user account
        // May throw an exception if the user needs to re-authenticate
        await authPort.deleteUser();
        logger.t('User account deleted successfully');

        // After successfully deleting the user account, 
        // proceed to delete the profile data and associated storage
        await profileRepository.delete(userId);
        await storageRepository.deleteProfileFolder(userId);

        return DeleteProfileResult.completed;
      }
		} on Exception catch (e) {
			if (e.toString().contains('requires-recent-login')) {
				logger.t('User deletion requires re-authentication');
				return DeleteProfileResult.authRequired;
			}
			rethrow;
		}
	}
}
