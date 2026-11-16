import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:profile/l10n/profile_localizations.dart';
import 'package:profile/src/presentation/viewmodel/onboarding_wizard_cubit.dart';

class const OnboardingWizardStepIndicator({
  required final OnboardingWizardStep step,
  required final ValueChanged<OnboardingWizardStep>? onSelected,
  required final bool locationEnabled,
  super.key,
}) extends StatelessWidget {
  static const double touchTargetSize = 48;

  @override
  Widget build(BuildContext context) {
    final steps = OnboardingWizardStep.values;
    return SizedBox(
      height: touchTargetSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: AnimatedSmoothIndicator(
              activeIndex: step.index,
              count: steps.length,
              effect: WormEffect(
                activeDotColor: Colors.black,
                dotColor: Colors.black.withValues(alpha: 0.2),
                dotHeight: 12,
                dotWidth: 12,
                spacing: DesignSpec.spacingMd,
                // spacing:  - 12,
              ),
            ),
          ),
          Row(
            children: [
              for (final item in steps)
                _buildTarget(context, item, steps.length),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTarget(
    BuildContext context,
    OnboardingWizardStep item,
    int count,
  ) {
    final enabled =
        onSelected != null && (item != .location || locationEnabled);
    return Semantics(
      label: ProfileLocalizations.of(context)
          .profileWizardStepLabel(item.index + 1, count),
      button: true,
      selected: item == step,
      enabled: enabled,
      child: GestureDetector(
        key: ValueKey('onboarding_wizard_step_${item.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onSelected!(item) : null,
        child: const SizedBox(
          width: touchTargetSize,
          height: touchTargetSize,
        ),
      ),
    );
  }
}
