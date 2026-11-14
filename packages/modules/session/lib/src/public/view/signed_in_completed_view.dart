import 'package:material_ui/material_ui.dart';

import 'package:core/core.dart';
import 'package:profile/profile.dart';
import 'package:social/social.dart';

import '../model/update_profile_stats_result.dart';

import 'session_result.dart';

class const SignedInCompletedView({
  required final String profileId,
  required final UpdateProfileStatsResult updateResult,
  final bool showStatsOnFinishScreen = true,
  final bool usePresenceFeature = true,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (usePresenceFeature == false && showStatsOnFinishScreen == false) {
      return SizedBox.expand(
        child: Center(
          child: SessionResult(
            session: updateResult.session,
            profile: updateResult.updatedProfile,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DesignSpec.breakpointSm,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignSpec.paddingLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Gap.xl(),
                  SessionResult(
                    session: updateResult.session,
                    profile: updateResult.updatedProfile,
                  ),
                  Gap.xxl(),
                  if (showStatsOnFinishScreen)
                    MilestoneProgressView(
                      statsReport: updateResult.updatedProfile.statsReport,
                      showAnimation: updateResult.updatedProfile
                          .consecutiveDaysProgressCheck(
                            updateResult.oldProfile,
                          ),
                      textColor: Colors.white,
                    ),
                  if (showStatsOnFinishScreen) Gap.large(),
                  if (showStatsOnFinishScreen)
                    ProgressSummary(
                      oldProfile: updateResult.oldProfile,
                      updatedProfile: updateResult.updatedProfile,
                    ),
                  if (usePresenceFeature) Gap.xxl(),
                  if (usePresenceFeature)
                    PresenceArea.withCubit(
                      profileId: updateResult.updatedProfile.id,
                      onCubitCreated: (cubit) {
                        cubit.loadPresenceData(
                          ownProfileId: updateResult.updatedProfile.id,
                          limit: 18,
                          windowSize: const Duration(minutes: 120),
                        );
                      },
                      builder: (context, state, area) {
                        // final hasPresence = switch (state) {
                        //   PresenceLoadedState(:final presenceList) ||
                        //   PresenceLoadingMoreState(:final presenceList) => presenceList.isNotEmpty,
                        //   _ => false,
                        // };
                        final hasPresence = true;
                        return Column(
                          children: [
                            if (hasPresence)
                              LocationPromptCard(
                                profile: updateResult.updatedProfile,
                              ),
                            area,
                          ],
                        );
                      },
                    ),
                  SizedBox(
                    // as per size of bottom area gradient - safearea bottom
                    // see [session_completed_screen.dart]
                    height: 140,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
