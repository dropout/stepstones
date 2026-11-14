import 'package:material_ui/material_ui.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:core/core.dart';
import 'package:profile/l10n/profile_localizations.dart';
import 'package:profile/src/presentation/viewmodel/profile_wizard_cubit.dart';

class const ProfileWizardStepIndicator({
  required final ProfileWizardStep step,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = ProfileWizardStep.values.length;
    return Column(
      children: [
        AnimatedSmoothIndicator(
          activeIndex: step.index,
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
              .profileWizardStepLabel(step.index + 1, count),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
