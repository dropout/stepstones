import 'package:profile/profile.dart';
import '../entity/session_entity.dart';


/// Outcome of saving a session into the profile; lives here because
/// it carries profile-module types the domain entities must not import.
typedef ProfileUpdateResult = ({
  Profile oldProfile,
  Profile updatedProfile,
  SessionEntity session,
});

/// An interface that defines the contract for session-related operations
abstract interface class SessionAppPort {

  /// Updates the profile statistics with the completed session.
  Future<({Profile originalProfile, Profile updatedProfile})> updateProfileWithSession(
    String profileId,
    SessionEntity session,
  );

  /// Saves sessions statistical data to the StatsPublicApi.
  Future<void> saveSessionStats(
    String profileId, 
    SessionEntity session
  );

  /// Checks if the Mindful Minutes service is authorized.
  Future<bool> isMindfulMinutesAuthorized();

  /// Logs a completed session to the Mindful Minutes service.
  Future<void> logMindfulMinutes(DateTime startTime, DateTime endTime);

}
