import 'package:material_ui/material_ui.dart';
import 'package:profile/profile.dart';
import 'package:core/core.dart';


class StatsDataAreaSliver extends StatelessWidget {
  final Profile profile;
  final String profileName;
  final String? profilePhotoBlurhash;

  const StatsDataAreaSliver({
    required this.profile,
    required this.profileName,
    required this.profilePhotoBlurhash,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(DesignSpec.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DetailedProfileView(
              profileId: profile.id,
              profileName: profile.displayName,
              signupDate: profile.signupDate,
              profileStatsReport: profile.statsReport,
              profilePhotoBlurhash: profile.photoBlurhash,
            ),
            Gap.medium(),
            DetailedConsecutiveDaysView(
              profileStatsReport: profile.statsReport,
            ),
            Gap.medium(),
            DetailedMilestonesView(profileStatsReport: profile.statsReport),
            Gap.medium(),
            DetailedSummaryView(profileStatsReport: profile.statsReport),
          ],
        ),
      ),
    );
  }
}
