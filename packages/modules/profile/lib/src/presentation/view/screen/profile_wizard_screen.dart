import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get_it/get_it.dart';

import 'package:profile/l10n/profile_localizations.dart';

import 'package:core/core.dart';
import 'package:profile/src/presentation/view/profile_edit_form.dart';
import 'package:profile/src/presentation/viewmodel/profile_edit_cubit.dart';
import 'package:profile/src/public/model/profile.dart';
import 'package:profile/src/public/viewmodel/profile_cubit.dart';

class const ProfileWizardScreen({
  required final String profileId,
  super.key,
}) extends StatefulWidget {
  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen>
    with DefaultScreenSetupHelpersMixin {
  ProcessingState formProcessingState = ProcessingState.idle;
  final GlobalKey<FormBuilderState> formStateKey =
      GlobalKey<FormBuilderState>();

  void _onSave(BuildContext context, Profile profile) {
    FormBuilderState? formState = formStateKey.currentState;
    if (formState != null && formState.saveAndValidate()) {
      setState(() {
        formProcessingState = ProcessingState.processing;
      });
      Map<String, dynamic>? values = formState.value;
      context.read<ProfileEditCubit>().updateProfile(
        profile: profile,
        formData: values,
        completeProfile: true,
        onComplete: (profile) {
          setState(() {
            formProcessingState = ProcessingState.completed;
          });
          context.services.hapticsService.success();
        },
        onError: (e, stack) {
          setState(() {
            formProcessingState = ProcessingState.idle;
          });
          context.services.hapticsService.error();
        },
      );
      context.services.hapticsService.tap();
    } else {
      context.services.hapticsService.error();
    }
  }

  void _onSignOut(BuildContext context) {
    showAppDialog(context, SignoutDialog(
      onSignOut: () async => context.read<ProfileCubit>().clearData(),
    ));
    context.hapticsTap();
  }

  void _onFormChanged(BuildContext context) {
    setState(() {
      formProcessingState = ProcessingState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmartBlocProvider<ProfileEditCubit, ProfileEditState>(
      create: (context) => GetIt.I<ProfileEditCubit>()..loadProfile(widget.profileId),
      builder: (context, state) {
        return switch (state) {
          ProfileEditLoadingState() => DefaultScreenSetup(
              title: ProfileLocalizations.of(context).profileWizardTitle,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              slivers: [buildLoadingSliver(context)],
            ),
          ProfileEditErrorState() => DefaultScreenSetup(
              title: ProfileLocalizations.of(context).profileWizardTitle,
              enableTitleSliver: false,
              backgroundColor: Theme.of(context).colorScheme.error,
              appBarBackgroundColor: Theme.of(context).colorScheme.error,
              backButton: CustomBackButton.light(),
              titleColor: Colors.white,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              slivers: [buildErrorSliver(context)],
            ),
          ProfileEditLoadedState() => DefaultScreenSetup(
              title: ProfileLocalizations.of(context).profileWizardTitle,
              slivers: [
                // The profile edit form.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSpec.paddingLg,
                    ),
                    child: ProfileEditForm(
                      profile: state.profile,
                      formStateKey: formStateKey,
                      onChanged: () => _onFormChanged(context),
                    ),
                  ),
                ),

                // Display a sign out button under the edit form
                // just in case the user cannot continue
                // with the profile wizard.
                SliverSafeArea(
                  top: false,
                  sliver: SliverToBoxAdapter(
                    // The layout widgets below are needed to
                    // restrict button size to its content,
                    // otherwise the button would end up
                    // using the whole width.
                    child: SizedBox(
                      height: DesignSpec.spacing4xl,
                      child: Center(
                        child: TextButton(
                          onPressed: () => _onSignOut(context),
                          child: Text(
                            ProfileLocalizations.of(
                              context,
                            ).signOut.toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              overlay: buildOverlayActionButton(context, state.profile)
            ),
          _ => DefaultScreenSetup(
              title: ProfileLocalizations.of(context).editProfile,
              scrollPhysics: const NeverScrollableScrollPhysics(),
            ),
        };
        
      },  
    );
  }

  Widget buildOverlayActionButton(BuildContext context, Profile profile) =>
    switch (formProcessingState) {
      .idle => AppButton(
          text: context.coreL10n.profileSaveButtonIdle.toUpperCase(),
          onTap: () => _onSave(context, profile),
        ),
      .processing => AppButton(
          text: context.coreL10n.profileSaveButtonSaving.toUpperCase(),
        ),
      .completed => AppButton(
          text: context.coreL10n.profileSaveButtonSaved.toUpperCase(),
          bColor: Colors.green.shade600,
        ),
      _ => AppButton(
          text: context.coreL10n.profileSaveButtonIdle.toUpperCase(),
          onTap: () => _onSave(context, profile),
        ),
    };
  
}
