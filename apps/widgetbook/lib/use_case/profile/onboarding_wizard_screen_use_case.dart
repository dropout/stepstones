// ignore_for_file: implementation_imports

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart' show OnboardingIntent;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:profile/profile.dart';
import 'package:profile/src/presentation/view/screen/onboarding_wizard_screen.dart';
import 'package:profile/src/presentation/viewmodel/onboarding_wizard_cubit.dart';
import 'package:profile/src/presentation/viewmodel/profile_edit_cubit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

class _MockProfileEditCubit extends MockCubit<ProfileEditState>
    implements ProfileEditCubit {}

class _MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

void configureOnboardingWizardUseCase() {
  final profile = Profile.anonymous().copyWith(
    id: 'widgetbook-profile',
    firstName: 'Layman',
    lastName: 'Pang',
    signupDate: DateTime(2024),
  );
  final getIt = GetIt.instance;

  if (getIt.isRegistered<ProfileEditCubit>()) {
    getIt.unregister<ProfileEditCubit>();
  }
  getIt.registerFactory<ProfileEditCubit>(() {
    final cubit = _MockProfileEditCubit();
    whenListen(
      cubit,
      const Stream<ProfileEditState>.empty(),
      initialState: ProfileEditState.loaded(profile: profile),
    );
    when(() => cubit.loadProfile(any())).thenAnswer((_) {});
    return cubit;
  });
}

@widgetbook.UseCase(
  name: 'Default',
  type: OnboardingWizardScreen,
  path: '[Profile]/internal/screen/',
)
Widget buildOnboardingWizardScreen(BuildContext context) {
  final step = context.knobs.object.dropdown(
    label: 'Step',
    options: OnboardingWizardStep.values,
    labelBuilder: (s) => s.name,
  );
  final intent = context.knobs.object.dropdown(
    label: 'Intent',
    options: OnboardingIntent.values,
    labelBuilder: (i) => i.name,
  );
  final profileCubit = _MockProfileCubit();
  when(() => profileCubit.state).thenReturn(const ProfileState.initial());

  return BlocProvider<ProfileCubit>.value(
    value: profileCubit,
    // The key rebuilds the screen so the cubit picks up the new step.
    child: OnboardingWizardScreen(
      key: ValueKey((step, intent)),
      profileId: 'widgetbook-profile',
      intent: intent,
      initialStep: step,
    ),
  );
}
