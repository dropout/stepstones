import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get_it/get_it.dart';

import 'package:profile/l10n/profile_localizations.dart';

import 'package:core/core.dart';
import 'package:profile/src/presentation/view/profile_basics_fields.dart';
import 'package:profile/src/presentation/view/profile_location_field.dart';
import 'package:profile/src/presentation/view/wizard/onboarding_features_step.dart';
import 'package:profile/src/presentation/view/wizard/onboarding_wizard_step_indicator.dart';
import 'package:profile/src/presentation/viewmodel/onboarding_wizard_cubit.dart';
import 'package:profile/src/presentation/viewmodel/profile_edit_cubit.dart';
import 'package:profile/src/public/model/profile.dart';
import 'package:profile/src/public/model/profile_settings.dart';

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

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> with DefaultScreenSetupHelpersMixin {
  GlobalKey<FormBuilderState> _basicsFormKey = GlobalKey<FormBuilderState>();
  GlobalKey<FormBuilderState> _featuresFormKey = GlobalKey<FormBuilderState>();
  GlobalKey<FormBuilderState> _locationFormKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic>? _basicsDraft;
  Map<String, dynamic>? _featuresDraft;
  Map<String, dynamic>? _locationDraft;

  void _onSubmit(BuildContext context, Profile profile, OnboardingWizardStep step) {
    final wizardCubit = context.read<OnboardingWizardCubit>();
    if (wizardCubit.state.saving == ProcessingState.processing) return;
    final formKey = switch (step) {
      // The intro has nothing to save.
      .intro => null,
      .basics => _basicsFormKey,
      .features => _featuresFormKey,
      .location => _locationFormKey,
    };
    if (formKey == null) {
      context.logEvent(name: 'onboarding_intro_continued', parameters: {'intent': widget.intent.name});
      context.hapticsTap();
      FocusManager.instance.primaryFocus?.unfocus();
      wizardCubit.next();
      return;
    }
    final formState = formKey.currentState;
    if (formState == null || !formState.saveAndValidate()) {
      context.services.hapticsService.error();
      return;
    }

    wizardCubit.setSaving(ProcessingState.processing);
    final formData = formState.value;
    void onSaved(Profile updatedProfile) {
      if (!context.mounted) return;
      context.services.hapticsService.success();
      context.logEvent(
        name: 'profile_wizard_step_completed',
        parameters: {
          'step': step.name,
          if (step == OnboardingWizardStep.features)
            for (final key in [ProfileSettings.showStatsKey, ProfileSettings.usePresenceFeatureKey])
              key: '${formData[key]}',
        },
      );
      switch (step) {
        case .intro:
          break;
        case .basics:
          FocusManager.instance.primaryFocus?.unfocus();
          _preserveStep(context, step);
          wizardCubit.next();
        case .features:
          // Location only serves presence, so skip it when presence is off.
          if (formData[ProfileSettings.usePresenceFeatureKey] == false) {
            _finish(context, updatedProfile);
          } else {
            _preserveStep(context, step);
            wizardCubit.next();
          }
        case .location:
          _finish(context, updatedProfile);
      }
    }

    void onError(Object? e, StackTrace stack) {
      if (!context.mounted) return;
      wizardCubit.setSaving(ProcessingState.idle);
      context.services.hapticsService.error();
    }

    final editCubit = context.read<ProfileEditCubit>();
    if (step == OnboardingWizardStep.features) {
      editCubit.updateProfileSettings(
        profile: profile,
        settingsFormData: formData,
        onComplete: (_) => onSaved(profile),
        onError: onError,
      );
    } else {
      editCubit.updateProfile(
        profile: profile,
        formData: formData,
        // Basics make the profile usable; location stays optional.
        completeProfile: step == OnboardingWizardStep.basics,
        onComplete: onSaved,
        onError: onError,
      );
    }
    context.services.hapticsService.tap();
  }

  void _preserveStep(BuildContext context, OnboardingWizardStep step) {
    switch (step) {
      case .intro:
        break;
      case .basics:
        final form = _basicsFormKey.currentState;
        if (form != null) {
          _basicsDraft = form.instantValue;
          if (form.isDirty) {
            context.read<OnboardingWizardCubit>().invalidate(OnboardingWizardStep.basics);
          }
        }
        _basicsFormKey = GlobalKey<FormBuilderState>();
      case .features:
        final form = _featuresFormKey.currentState;
        if (form != null) {
          _featuresDraft = form.instantValue;
          if (form.isDirty) {
            context.read<OnboardingWizardCubit>().invalidate(OnboardingWizardStep.features);
          }
        }
        _featuresFormKey = GlobalKey<FormBuilderState>();
      case .location:
        _locationDraft = _locationFormKey.currentState?.instantValue;
        _locationFormKey = GlobalKey<FormBuilderState>();
    }
  }

  void _onSelectStep(BuildContext context, OnboardingWizardStep currentStep, OnboardingWizardStep selectedStep) {
    final cubit = context.read<OnboardingWizardCubit>();
    if (cubit.state.saving == ProcessingState.processing ||
        selectedStep == currentStep ||
        !cubit.canOpen(selectedStep)) {
      return;
    }
    _preserveStep(context, currentStep);
    FocusManager.instance.primaryFocus?.unfocus();
    context.hapticsTap();
    cubit.goTo(selectedStep);
  }

  void _finish(BuildContext context, Profile profile) {
    context.services.profileNavigator.navigateToProfile(profile.id, type: .replace);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingWizardCubit>(
      create: (_) => OnboardingWizardCubit(initialStep: widget.initialStep),
      child: SmartBlocProvider<ProfileEditCubit, ProfileEditState>(
        create: (context) => GetIt.I<ProfileEditCubit>()..loadProfile(widget.profileId),
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
            ProfileEditLoadedState() => BlocBuilder<OnboardingWizardCubit, OnboardingWizardState>(
              builder: (context, wizardState) => _buildLoaded(context, state.profile, wizardState),
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

  Widget _buildLoaded(BuildContext context, Profile profile, OnboardingWizardState wizardState) {
    final step = wizardState.step;
    final wizardCubit = context.read<OnboardingWizardCubit>();
    return DefaultScreenSetup(
      enableTitleSliver: false,
      enableAppBarTitle: false,
      enableAppBar: _showBackButton,
      enableBackButton: _showBackButton,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignSpec.paddingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: Durations.medium1,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final child in previousChildren) IgnorePointer(child: ExcludeSemantics(child: child)),
                      ?currentChild,
                    ],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(step),
                    child: switch (step) {
                      .intro => _buildIntro(context),
                      .basics => _buildBasics(context, profile, wizardState),
                      .features => _buildFeatures(context, profile, wizardState),
                      .location => _buildLocation(context, profile, wizardState),
                    },
                  ),
                ),
                Gap.medium(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom:
                DesignSpec.bottomActionSpacing +
                OnboardingWizardStepIndicator.touchTargetSize +
                MediaQuery.viewPaddingOf(context).bottom,
          ),
        ),
      ],
      overlay: SafeArea(
        top: false,
        child: Align(
          alignment: const Alignment(0.0, 1.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: DesignSpec.paddingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OnboardingWizardStepIndicator(
                  step: step,
                  isStepEnabled: wizardCubit.canOpen,
                  onSelected: wizardState.saving == ProcessingState.processing
                      ? null
                      : (selectedStep) => _onSelectStep(context, step, selectedStep),
                ),
                _buildActionButton(context, profile, wizardState),
              ],
            ),
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
    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: .w500);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap.large(),
        Text(
          _introTitle(l10n),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Gap.medium(),
        Text(description, key: const Key('onboarding_wizard_intro_message'), style: bodyStyle),
        if (widget.intent == OnboardingIntent.firstSignIn) ...[
          Gap.medium(),
          for (final benefit in [
            l10n.onboardingBenefitChanting,
            l10n.onboardingBenefitPresence,
            l10n.onboardingBenefitStats,
          ]) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Text('\u2022', style: bodyStyle)),
                Gap.small(),
                Expanded(child: Text(benefit, style: bodyStyle)),
              ],
            ),
            Gap.small(),
          ],
          Gap.small(),
          Text(l10n.onboardingCheckProfilePrompt, style: bodyStyle),
        ],
      ],
    );
  }

  Widget _buildBasics(BuildContext context, Profile profile, OnboardingWizardState wizardState) {
    final l10n = ProfileLocalizations.of(context);
    return FormBuilder(
      key: _basicsFormKey,
      enabled: wizardState.saving != ProcessingState.processing,
      initialValue: _basicsDraft ?? const {},
      onChanged: () {
        final cubit = context.read<OnboardingWizardCubit>();
        if (cubit.canOpen(OnboardingWizardStep.features) && (_basicsFormKey.currentState?.isDirty ?? false)) {
          cubit.invalidate(OnboardingWizardStep.basics);
          setState(() {});
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap.large(),
          Text(
            l10n.profileBasicsTitle,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Gap.medium(),
          Text(
            l10n.profileBasicsDescription,
            key: const Key('onboarding_wizard_basics_message'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: .w500),
          ),
          Gap.large(),
          ProfileBasicsFields(
            profile: _basicsDraft == null
                ? profile
                : profile.copyWith(
                    firstName: _basicsDraft!['firstName'] as String? ?? profile.firstName,
                    lastName: _basicsDraft!['lastName'] as String? ?? profile.lastName,
                  ),
            formStateKey: _basicsFormKey,
          ),
        ],
      ),
    );
  }

  bool _presenceEnabled(Profile profile) =>
      (_featuresFormKey.currentState?.instantValue ?? _featuresDraft)?[ProfileSettings.usePresenceFeatureKey]
          as bool? ??
      profile.settings.usePresenceFeature;

  Widget _buildFeatures(BuildContext context, Profile profile, OnboardingWizardState wizardState) {
    final draft = _featuresDraft;
    return OnboardingFeaturesStep(
      formKey: _featuresFormKey,
      enabled: wizardState.saving != ProcessingState.processing,
      settings: draft == null
          ? profile.settings
          : profile.settings.copyWith(
              showStats: draft[ProfileSettings.showStatsKey] as bool? ?? profile.settings.showStats,
              usePresenceFeature:
                  draft[ProfileSettings.usePresenceFeatureKey] as bool? ?? profile.settings.usePresenceFeature,
            ),
      onChanged: () {
        if (_featuresFormKey.currentState?.isDirty ?? false) {
          context.read<OnboardingWizardCubit>().invalidate(OnboardingWizardStep.features);
        }
        // Rebuilds the indicator and the action button label.
        setState(() {});
      },
    );
  }

  Widget _buildLocation(BuildContext context, Profile profile, OnboardingWizardState wizardState) {
    final l10n = ProfileLocalizations.of(context);
    return FormBuilder(
      key: _locationFormKey,
      enabled: wizardState.saving != ProcessingState.processing,
      initialValue: _locationDraft ?? const {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap.large(),
          Text(
            l10n.locationPitchTitle,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Gap.medium(),
          Text(l10n.locationPitchBody, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: .w500)),
          Gap.large(),
          ProfileLocationField(
            profile: _locationDraft == null
                ? profile
                : profile.copyWith(location: _locationDraft!['location'] as Location?),
            formStateKey: _locationFormKey,
            showInfoCard: false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Profile profile, OnboardingWizardState wizardState) {
    final l10n = ProfileLocalizations.of(context);
    final text = switch (wizardState.step) {
      .intro => l10n.profileWizardCheck,
      .basics => l10n.profileWizardContinue,
      .features => _presenceEnabled(profile) ? l10n.profileWizardContinue : l10n.profileWizardFinish,
      .location => l10n.profileWizardFinish,
    }.toUpperCase();

    if (wizardState.saving == ProcessingState.processing) {
      return AppButton(text: context.coreL10n.profileSaveButtonSaving.toUpperCase());
    }
    return AppButton(text: text, onTap: () => _onSubmit(context, profile, wizardState.step));
  }
}
