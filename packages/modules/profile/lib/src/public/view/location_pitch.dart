import 'package:material_ui/material_ui.dart';

import 'package:core/core.dart';
import 'package:profile/l10n/profile_localizations.dart';

/// Explains why adding a city is worthwhile; shared by the wizard
/// and the post-session prompt so the pitch stays consistent.
class const LocationPitch({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = ProfileLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on_outlined, color: AppColors.charcoal),
        Gap.xs(),
        Text(
          l10n.locationPitchTitle,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        Gap.xs(),
        Text(
          l10n.locationPitchBody,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.charcoal),
        ),
      ],
    );
  }
}
