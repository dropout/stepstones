import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile/src/presentation/viewmodel/profile_wizard_cubit.dart';

void main() {
  group('ProfileWizardCubit', () {
    test('starts on the basics step', () {
      final cubit = ProfileWizardCubit();
      expect(cubit.state.step, ProfileWizardStep.basics);
      expect(cubit.state.saving, ProcessingState.idle);
    });

    test('next moves to location and resets saving', () {
      final cubit = ProfileWizardCubit()
        ..setSaving(ProcessingState.processing);
      cubit.next();
      expect(cubit.state.step, ProfileWizardStep.location);
      expect(cubit.state.saving, ProcessingState.idle);
    });
  });
}
