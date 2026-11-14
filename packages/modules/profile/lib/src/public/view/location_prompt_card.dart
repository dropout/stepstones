import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:profile/l10n/profile_localizations.dart';
import 'package:profile/src/presentation/view/profile_location_field.dart';
import 'package:profile/src/presentation/viewmodel/profile_edit_cubit.dart';
import 'package:profile/src/public/model/profile.dart';
import 'package:profile/src/public/view/location_pitch.dart';
import 'package:profile/src/public/viewmodel/location_prompt_cubit.dart';

/// One-time nudge to add a city; hides itself once dismissed or saved.
class const LocationPromptCard({required final Profile profile, super.key})
    extends StatelessWidget {
  void _onAdd(BuildContext context) {
    context.hapticsTap();
    context.logEvent(name: 'location_prompt_add_pressed');
    final cubit = context.read<LocationPromptCubit>();
    showAppDialog(
      context,
      LocationPromptDialog(profile: profile, onSaved: cubit.dismiss),
    );
  }

  void _onSkip(BuildContext context) {
    context.hapticsTap();
    context.logEvent(name: 'location_prompt_dismissed');
    context.read<LocationPromptCubit>().dismiss();
  }

  @override
  Widget build(BuildContext context) {
    if (profile.location != null) return const SizedBox.shrink();

    return BlocProvider<LocationPromptCubit>(
      create: (_) => GetIt.I<LocationPromptCubit>()..load(),
      child: BlocBuilder<LocationPromptCubit, bool>(
        builder: (context, visible) {
          if (!visible) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignSpec.paddingLg),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.backgroundPaperLight,
                borderRadius: BorderRadius.circular(DesignSpec.paddingMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(DesignSpec.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LocationPitch(),
                    Gap.medium(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        DialogButton.secondary(
                          text: ProfileLocalizations.of(context)
                              .profileWizardSkip,
                          onPressed: () => _onSkip(context),
                        ),
                        DialogButton.primary(
                          text: ProfileLocalizations.of(context)
                              .locationPromptAction,
                          onPressed: () => _onAdd(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LocationPromptDialog extends StatefulWidget {
  final Profile profile;
  final Future<void> Function() onSaved;

  const LocationPromptDialog({
    required this.profile,
    required this.onSaved,
    super.key,
  });

  @override
  State<LocationPromptDialog> createState() => _LocationPromptDialogState();
}

class _LocationPromptDialogState extends State<LocationPromptDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  late final ProfileEditCubit _editCubit = GetIt.I<ProfileEditCubit>();
  bool _saving = false;

  @override
  void dispose() {
    _editCubit.close();
    super.dispose();
  }

  void _onSave() {
    final formState = _formKey.currentState;
    if (_saving || formState == null || !formState.saveAndValidate()) return;
    final location = formState.value['location'] as Location?;
    if (location == null) return;

    setState(() => _saving = true);
    _editCubit.updateProfile(
      profile: widget.profile,
      formData: {'location': location},
      onComplete: (_) async {
        context.services.hapticsService.success();
        context.logEvent(name: 'location_prompt_saved');
        await widget.onSaved();
        if (mounted) context.pop();
      },
      onError: (_, _) {
        if (mounted) setState(() => _saving = false);
        context.services.hapticsService.error();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundPaperLight,
      content: FormBuilder(
        key: _formKey,
        child: ProfileLocationField(
          profile: widget.profile,
          formStateKey: _formKey,
        ),
      ),
      actions: [
        DialogButton.secondary(
          text: ProfileLocalizations.of(context).profileWizardSkip,
          onPressed: () => context.pop(),
        ),
        DialogButton.primary(
          text: context.coreL10n.profileSaveButtonIdle,
          onPressed: _onSave,
        ),
      ],
    );
  }
}
