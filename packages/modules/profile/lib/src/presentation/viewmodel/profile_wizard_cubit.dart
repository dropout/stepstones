import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';

part 'profile_wizard_cubit.freezed.dart';

enum ProfileWizardStep { basics, location }

@freezed
abstract class ProfileWizardState with _$ProfileWizardState {
  const factory ProfileWizardState({
    @Default(ProfileWizardStep.basics) ProfileWizardStep step,
    @Default(ProcessingState.idle) ProcessingState saving,
  }) = _ProfileWizardState;
}

/// Tracks wizard navigation only; profile data lives in the edit cubit.
class ProfileWizardCubit extends Cubit<ProfileWizardState> {
  ProfileWizardCubit() : super(const ProfileWizardState());

  void setSaving(ProcessingState saving) =>
      emit(state.copyWith(saving: saving));

  void next() => emit(
    state.copyWith(
      step: ProfileWizardStep.location,
      saving: ProcessingState.idle,
    ),
  );
}
