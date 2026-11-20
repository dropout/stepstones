import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';

part 'onboarding_wizard_cubit.freezed.dart';

enum OnboardingWizardStep { intro, basics, features, location }

@freezed
abstract class OnboardingWizardState with _$OnboardingWizardState {
  const factory OnboardingWizardState({
    @Default(OnboardingWizardStep.intro) OnboardingWizardStep step,
    @Default(ProcessingState.idle) ProcessingState saving,
  }) = _OnboardingWizardState;
}

/// Tracks wizard navigation only; profile data lives in the edit cubit.
class OnboardingWizardCubit extends Cubit<OnboardingWizardState> {
  OnboardingWizardCubit({OnboardingWizardStep initialStep = OnboardingWizardStep.intro})
    : _unlockedIndex = math.max(OnboardingWizardStep.basics.index, initialStep.index),
      super(OnboardingWizardState(step: initialStep));

  // Steps after basics stay locked until each previous step has been saved.
  int _unlockedIndex;

  bool canOpen(OnboardingWizardStep step) => step.index <= _unlockedIndex;

  /// Locks every step after [step] until [step] is saved again.
  void invalidate(OnboardingWizardStep step) => _unlockedIndex = math.min(_unlockedIndex, step.index);

  void setSaving(ProcessingState saving) => emit(state.copyWith(saving: saving));

  void goTo(OnboardingWizardStep step) {
    if (state.saving == ProcessingState.processing || step == state.step || !canOpen(step)) {
      return;
    }
    emit(state.copyWith(step: step));
  }

  void next() {
    final steps = OnboardingWizardStep.values;
    final step = steps[math.min(state.step.index + 1, steps.length - 1)];
    _unlockedIndex = math.max(_unlockedIndex, step.index);
    emit(state.copyWith(step: step, saving: ProcessingState.idle));
  }
}
