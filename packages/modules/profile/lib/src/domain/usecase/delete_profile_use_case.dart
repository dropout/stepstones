import 'package:core/core.dart';
import 'package:profile/src/domain/repository/profile_repository.dart';
import 'package:profile/src/domain/service/profile_auth_port.dart';

enum DeleteProfileResult {
	completed,
	authRequired,
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

	Future<DeleteProfileResult> execute() async {
		try {
			logger.t('Attempting to delete user account');
      final userId = await authPort.getAuthenticatedUserId();

      // First check if the user is authenticated before proceeding with deletion
      if (userId == null) {
        logger.t('User is not authenticated. Cannot delete profile.');
        return DeleteProfileResult.authRequired;
      } else {      
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
