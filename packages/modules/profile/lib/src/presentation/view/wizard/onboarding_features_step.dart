import 'package:core/core.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';

import 'package:profile/l10n/profile_localizations.dart';
import 'package:profile/src/presentation/view/settings/profile_settings_switch.dart';
import 'package:profile/src/public/model/profile_settings.dart';

/// Onboarding step explaining the stats and presence settings.
class const OnboardingFeaturesStep({
  required final GlobalKey<FormBuilderState> formKey,
  required final ProfileSettings settings,
  required final bool enabled,
  final VoidCallback? onChanged,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = ProfileLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return FormBuilder(
      key: formKey,
      enabled: enabled,
      onChanged: onChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap.large(),
          Text(l10n.onboardingFeaturesTitle, style: textTheme.headlineLarge?.copyWith(fontWeight: .bold)),
          Gap.medium(),
          Text(
            l10n.onboardingFeaturesDescription,
            key: const Key('onboarding_wizard_features_message'),
            style: textTheme.bodyLarge?.copyWith(fontWeight: .w500),
          ),
          Gap.large(),
          _FeatureSection(
            explanation: l10n.onboardingStatsExplanation,
            toggle: ProfileSettingsSwitch(
              key: const Key('onboarding_wizard_show_stats_switch'),
              name: ProfileSettings.showStatsKey,
              title: l10n.showStatsOnFinishScreenTitle,
              initialValue: settings.showStats,
            ),
          ),
          Gap.large(),
          _FeatureSection(
            explanation: l10n.onboardingPresenceExplanation,
            toggle: ProfileSettingsSwitch(
              key: const Key('onboarding_wizard_use_presence_switch'),
              name: ProfileSettings.usePresenceFeatureKey,
              title: l10n.usePresenceFeatureTitle,
              initialValue: settings.usePresenceFeature,
            ),
          ),
        ],
      ),
    );
  }
}

class const _FeatureSection({
  required final String explanation,
  required final Widget toggle,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        toggle,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignSpec.paddingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                explanation, 
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: .w500
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
