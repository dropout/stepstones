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
  }) : super(OnboardingWizardState(step: initialStep));

  void setSaving(ProcessingState saving) =>
      emit(state.copyWith(saving: saving));

  void next() => emit(
    state.copyWith(
      step: switch (state.step) {
        .intro => OnboardingWizardStep.basics,
        .basics || .location => OnboardingWizardStep.location,
      },
      saving: ProcessingState.idle,
    ),
  );
}
