import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';

part 'onboarding_wizard_cubit.freezed.dart';

enum OnboardingWizardStep { intro, basics, location }

@freezed
abstract class OnboardingWizardState with _$OnboardingWizardState {
  const factory OnboardingWizardState({
    @Default(OnboardingWizardStep.intro) OnboardingWizardStep step,
    @Default(ProcessingState.idle) ProcessingState saving,
  }) = _OnboardingWizardState;
}

/// Tracks wizard navigation only; profile data lives in the edit cubit.
class OnboardingWizardCubit extends Cubit<OnboardingWizardState> {
  OnboardingWizardCubit({
    OnboardingWizardStep initialStep = OnboardingWizardStep.intro,
  }) : _basicsCompleted = initialStep == OnboardingWizardStep.location,
       super(OnboardingWizardState(step: initialStep));

  bool _basicsCompleted;

  bool get canOpenLocation => _basicsCompleted;

  void invalidateBasics() => _basicsCompleted = false;

  void setSaving(ProcessingState saving) =>
      emit(state.copyWith(saving: saving));

  void goTo(OnboardingWizardStep step) {
    if (state.saving == ProcessingState.processing ||
        step == state.step ||
        (step == OnboardingWizardStep.location && !_basicsCompleted)) {
      return;
    }
    emit(state.copyWith(step: step));
  }

  void next() {
    final step = switch (state.step) {
      .intro => OnboardingWizardStep.basics,
      .basics || .location => OnboardingWizardStep.location,
    };
    if (state.step == OnboardingWizardStep.basics) {
      _basicsCompleted = true;
    }
    emit(state.copyWith(step: step, saving: ProcessingState.idle));
  }
}
