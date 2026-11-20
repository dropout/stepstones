import 'package:material_ui/material_ui.dart';

import 'package:core/core.dart';
import 'package:profile/l10n/profile_localizations.dart';

/// Explains why adding a city is worthwhile.
class const LocationPitch({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = ProfileLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.locationPitchTitle,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: .bold,
            color: AppColors.charcoal,
          ),
        ),
        Gap.medium(),
        Text(
          l10n.locationPitchBody,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.charcoal,
            fontWeight: .w500,
          ),
        ),
      ],
    );
  }
}
