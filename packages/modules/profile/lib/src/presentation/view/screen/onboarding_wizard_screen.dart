import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get_it/get_it.dart';

import 'package:profile/l10n/profile_localizations.dart';

import 'package:core/core.dart';
import 'package:profile/src/presentation/view/profile_basics_fields.dart';
import 'package:profile/src/presentation/view/profile_location_field.dart';
import 'package:profile/src/presentation/view/wizard/onboarding_wizard_step_indicator.dart';
import 'package:profile/src/presentation/viewmodel/onboarding_wizard_cubit.dart';
import 'package:profile/src/public/view/location_pitch.dart';
import 'package:profile/src/presentation/viewmodel/profile_edit_cubit.dart';
import 'package:profile/src/public/model/profile.dart';
import 'package:profile/src/public/viewmodel/profile_cubit.dart';

class const OnboardingWizardScreen({
  required final String profileId,
  final OnboardingIntent intent = OnboardingIntent.firstSignIn,
  // Lets previews and tests start on any step.
  final OnboardingWizardStep initialStep = OnboardingWizardStep.intro,
  super.key,
}) extends StatefulWidget {
  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen>
    with DefaultScreenSetupHelpersMixin {
  final GlobalKey<FormBuilderState> _basicsFormKey =
      GlobalKey<FormBuilderState>();
  final GlobalKey<FormBuilderState> _locationFormKey =
      GlobalKey<FormBuilderState>();

  void _onSubmit(
    BuildContext context,
    Profile profile,
    OnboardingWizardStep step,
  ) {
    final formKey = switch (step) {
      // The intro has nothing to save.
      .intro => null,
      .basics => _basicsFormKey,
      .location => _locationFormKey,
    };
    if (formKey == null) {
      context.logEvent(
        name: 'onboarding_intro_continued',
        parameters: {'intent': widget.intent.name},
      );
      context.hapticsTap();
      context.read<OnboardingWizardCubit>().next();
      return;
    }
    final formState = formKey.currentState;
    if (formState == null || !formState.saveAndValidate()) {
      context.services.hapticsService.error();
      return;
    }

    final wizardCubit = context.read<OnboardingWizardCubit>();
    wizardCubit.setSaving(ProcessingState.processing);
    context.read<ProfileEditCubit>().updateProfile(
      profile: profile,
      formData: formState.value,
      // Basics make the profile usable; location stays optional.
      completeProfile: step == OnboardingWizardStep.basics,
      onComplete: (updatedProfile) {
        context.services.hapticsService.success();
        context.logEvent(
          name: 'profile_wizard_step_completed',
          parameters: {'step': step.name},
        );
        switch (step) {
          case .intro:
            break;
          case .basics:
            wizardCubit.next();
          case .location:
            _finish(context, updatedProfile);
        }
      },
      onError: (e, stack) {
        wizardCubit.setSaving(ProcessingState.idle);
        context.services.hapticsService.error();
      },
    );
    context.services.hapticsService.tap();
  }

  void _onSkipLocation(BuildContext context, Profile profile) {
    context.logEvent(name: 'profile_wizard_location_skipped');
    context.hapticsTap();
    _finish(context, profile);
  }

  void _finish(BuildContext context, Profile profile) {
    context.services.profileNavigator.navigateToProfile(
      profile.id,
      type: .replace,
    );
  }

  void _onSignOut(BuildContext context) {
    showAppDialog(
      context,
      SignoutDialog(
        onSignOut: () async => context.read<ProfileCubit>().clearData(),
      ),
    );
    context.hapticsTap();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingWizardCubit>(
      create: (_) => OnboardingWizardCubit(initialStep: widget.initialStep),
      child: SmartBlocProvider<ProfileEditCubit, ProfileEditState>(
        create: (context) =>
            GetIt.I<ProfileEditCubit>()..loadProfile(widget.profileId),
        builder: (context, state) {
          return switch (state) {
            ProfileEditLoadingState() => DefaultScreenSetup(
              enableTitleSliver: false,
              enableAppBarTitle: false,
              enableAppBar: _showBackButton,
              enableBackButton: _showBackButton,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              slivers: [buildLoadingSliver(context)],
            ),
            ProfileEditErrorState() => DefaultScreenSetup(
              enableTitleSliver: false,
              enableAppBarTitle: false,
              backgroundColor: Theme.of(context).colorScheme.error,
              appBarBackgroundColor: Theme.of(context).colorScheme.error,
              backButton: CustomBackButton.light(),
              titleColor: Colors.white,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              slivers: [buildErrorSliver(context)],
            ),
            ProfileEditLoadedState() =>
              BlocBuilder<OnboardingWizardCubit, OnboardingWizardState>(
                builder: (context, wizardState) =>
                    _buildLoaded(context, state.profile, wizardState),
              ),
            _ => DefaultScreenSetup(
              enableTitleSliver: false,
              enableAppBarTitle: false,
              enableAppBar: _showBackButton,
              enableBackButton: _showBackButton,
              scrollPhysics: const NeverScrollableScrollPhysics(),
            ),
          };
        },
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    Profile profile,
    OnboardingWizardState wizardState,
  ) {
    final step = wizardState.step;
    return DefaultScreenSetup(
      enableTitleSliver: false,
      enableAppBarTitle: false,
      enableAppBar: _showBackButton,
      enableBackButton: _showBackButton,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpec.paddingLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (step != .intro) ...[
                  Center(child: OnboardingWizardStepIndicator(step: step)),
                  Gap.large(),
                ],
                AnimatedSwitcher(
                  duration: Durations.medium1,
                  child: switch (step) {
                    .intro => _buildIntro(context),
                    .basics => _buildBasics(context, profile),
                    .location => FormBuilder(
                      key: _locationFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LocationPitch(),
                          Gap.large(),
                          ProfileLocationField(
                            profile: profile,
                            formStateKey: _locationFormKey,
                          ),
                        ],
                      ),
                    ),
                  },
                ),
                Gap.medium(),
              ],
            ),
          ),
        ),
        // SliverSafeArea(
        //   top: false,
        //   sliver: SliverToBoxAdapter(
        //     child: SizedBox(
        //       height: DesignSpec.spacing4xl,
        //       child: Center(
        //         child: switch (step) {
        //           // Sign out stays available in case the user cannot continue.
        //           .intro || .basics => _textButton(
        //             context,
        //             ProfileLocalizations.of(context).signOut,
        //             () => _onSignOut(context),
        //           ),
        //           .location => _textButton(
        //             context,
        //             ProfileLocalizations.of(context).profileWizardSkip,
        //             () => _onSkipLocation(context, profile),
        //           ),
        //         },
        //       ),
        //     ),
        //   ),
        // ),
      ],
      overlay: SafeArea(
        top: false,
        child: Align(
          alignment: const Alignment(0.0, 1.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: DesignSpec.paddingLg),
            child: _buildActionButton(context, profile, wizardState),
          ),
        ),
      ),
    );
  }

  // Only the profile-button entry can be dismissed; first sign-in cannot.
  bool get _showBackButton => widget.intent == OnboardingIntent.completeProfile;

  String _introTitle(ProfileLocalizations l10n) => switch (widget.intent) {
    .firstSignIn => l10n.onboardingWelcomeTitle,
    .completeProfile => l10n.profileWizardTitle,
  };

  Widget _buildIntro(BuildContext context) {
    final l10n = ProfileLocalizations.of(context);
    final description = switch (widget.intent) {
      .firstSignIn => l10n.onboardingWelcomeDescription,
      .completeProfile => l10n.profileWizardDescription,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap.large(),
        Text(
          _introTitle(l10n),
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Gap.medium(),
        Text(
          description,
          key: const Key('onboarding_wizard_intro_message'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: .w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBasics(BuildContext context, Profile profile) {
    final l10n = ProfileLocalizations.of(context);
    return FormBuilder(
      key: _basicsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileBasicsTitle,
            style: Theme.of(context).textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Gap.medium(),
          Text(
            l10n.profileBasicsDescription,
            key: const Key('onboarding_wizard_basics_message'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: .w500,
            ),
          ),
          Gap.large(),
          ProfileBasicsFields(
            profile: profile,
            formStateKey: _basicsFormKey,
          ),
        ],
      ),
    );
  }

  Widget _textButton(BuildContext context, String text, VoidCallback onTap) =>
      TextButton(
        onPressed: onTap,
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge!
              .copyWith(fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildActionButton(
    BuildContext context,
    Profile profile,
    OnboardingWizardState wizardState,
  ) {
    final l10n = ProfileLocalizations.of(context);
    final text = switch (wizardState.step) {
      .intro || .basics => l10n.profileWizardContinue,
      .location => l10n.profileWizardFinish,
    }.toUpperCase();

    if (wizardState.saving == ProcessingState.processing) {
      return AppButton(
        text: context.coreL10n.profileSaveButtonSaving.toUpperCase(),
      );
    }
    return AppButton(
      text: text,
      onTap: () => _onSubmit(context, profile, wizardState.step),
    );
  }
}
