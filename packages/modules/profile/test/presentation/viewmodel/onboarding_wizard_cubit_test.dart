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
      final cubit = OnboardingWizardCubit(initialStep: OnboardingWizardStep.location);
      expect(cubit.state.step, OnboardingWizardStep.location);
      expect(cubit.canOpen(OnboardingWizardStep.features), isTrue);
    });

    test('next moves from intro to basics', () {
      final cubit = OnboardingWizardCubit()..next();
      expect(cubit.state.step, OnboardingWizardStep.basics);
    });

    test('next moves from basics to features and resets saving', () {
      final cubit = OnboardingWizardCubit()
        ..next()
        ..setSaving(ProcessingState.processing);
      cubit.next();
      expect(cubit.state.step, OnboardingWizardStep.features);
      expect(cubit.state.saving, ProcessingState.idle);
    });

    test('next moves from features to location and stays there', () {
      final cubit = OnboardingWizardCubit()
        ..next()
        ..next()
        ..next();
      expect(cubit.state.step, OnboardingWizardStep.location);
      cubit.next();
      expect(cubit.state.step, OnboardingWizardStep.location);
    });

    test('later steps open only after the previous ones are saved', () {
      final cubit = OnboardingWizardCubit();
      cubit.goTo(OnboardingWizardStep.features);
      cubit.goTo(OnboardingWizardStep.location);
      expect(cubit.state.step, OnboardingWizardStep.intro);

      cubit.goTo(OnboardingWizardStep.basics);
      cubit.goTo(OnboardingWizardStep.features);
      expect(cubit.state.step, OnboardingWizardStep.basics);

      cubit.next();
      expect(cubit.state.step, OnboardingWizardStep.features);
      cubit.goTo(OnboardingWizardStep.location);
      expect(cubit.state.step, OnboardingWizardStep.features);

      cubit.next();
      cubit.goTo(OnboardingWizardStep.intro);
      cubit.goTo(OnboardingWizardStep.location);
      expect(cubit.state.step, OnboardingWizardStep.location);
    });

    test('navigation is disabled during a save', () {
      final cubit = OnboardingWizardCubit()
        ..next()
        ..setSaving(ProcessingState.processing);
      cubit.goTo(OnboardingWizardStep.intro);
      expect(cubit.state.step, OnboardingWizardStep.basics);
      expect(cubit.state.saving, ProcessingState.processing);
    });

    test('invalidated basics must be saved again', () {
      final cubit = OnboardingWizardCubit()
        ..next()
        ..next()
        ..goTo(OnboardingWizardStep.basics)
        ..invalidate(OnboardingWizardStep.basics)
        ..goTo(OnboardingWizardStep.intro)
        ..goTo(OnboardingWizardStep.features);
      expect(cubit.state.step, OnboardingWizardStep.intro);
    });

    test('invalidated features lock location but keep features open', () {
      final cubit = OnboardingWizardCubit()
        ..next()
        ..next()
        ..next()
        ..goTo(OnboardingWizardStep.features)
        ..invalidate(OnboardingWizardStep.features);
      expect(cubit.canOpen(OnboardingWizardStep.features), isTrue);
      expect(cubit.canOpen(OnboardingWizardStep.location), isFalse);
      cubit.goTo(OnboardingWizardStep.location);
      expect(cubit.state.step, OnboardingWizardStep.features);
    });
  });
}
