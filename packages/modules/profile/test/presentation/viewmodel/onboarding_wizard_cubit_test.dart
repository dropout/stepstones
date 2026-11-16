import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile/src/presentation/viewmodel/onboarding_wizard_cubit.dart';

void main() {
  group('OnboardingWizardCubit', () {
    test('starts on the intro step', () {
      final cubit = OnboardingWizardCubit();
      expect(cubit.state.step, OnboardingWizardStep.intro);
      expect(cubit.state.saving, ProcessingState.idle);
    });

    test('can start on a given step', () {
      final cubit = OnboardingWizardCubit(
        initialStep: OnboardingWizardStep.location,
      );
      expect(cubit.state.step, OnboardingWizardStep.location);
    });

    test('next moves from intro to basics', () {
      final cubit = OnboardingWizardCubit()..next();
      expect(cubit.state.step, OnboardingWizardStep.basics);
    });

    test('next moves to location and resets saving', () {
      final cubit = OnboardingWizardCubit()
        ..next()
        ..setSaving(ProcessingState.processing);
      cubit.next();
      expect(cubit.state.step, OnboardingWizardStep.location);
      expect(cubit.state.saving, ProcessingState.idle);
    });
  });
}
