import 'package:material_ui/material_ui.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:core/core.dart';
import 'package:profile/l10n/profile_localizations.dart';
import 'package:profile/src/presentation/viewmodel/onboarding_wizard_cubit.dart';

class const OnboardingWizardStepIndicator({
  required final OnboardingWizardStep step,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // The intro is not a counted step.
    final count = OnboardingWizardStep.values.length - 1;
    final index = (step.index - 1).clamp(0, count - 1);
    return Column(
      children: [
        AnimatedSmoothIndicator(
          activeIndex: index,
          count: count,
          effect: WormEffect(
            activeDotColor: Colors.black,
            dotColor: Colors.black.withValues(alpha: 0.2),
            dotHeight: 12.0,
            dotWidth: 12.0,
          ),
        ),
        Gap.xs(),
        Text(
          ProfileLocalizations.of(context)
              .profileWizardStepLabel(index + 1, count),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
