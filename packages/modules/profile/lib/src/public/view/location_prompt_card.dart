import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:core/core.dart';
import 'package:profile/l10n/profile_localizations.dart';
import 'package:profile/src/public/model/profile.dart';
import 'package:profile/src/public/view/location_pitch.dart';
import 'package:profile/src/public/viewmodel/location_prompt_cubit.dart';

/// One-time nudge to add a city; thanks the user once saved.
class const LocationPromptCard({required final Profile profile, super.key})
    extends StatelessWidget {
  void _onAdd(BuildContext context) {
    context.hapticsTap();
    context.logEvent(name: 'location_prompt_add_pressed');
    final cubit = context.read<LocationPromptCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final errorMessage = context.coreL10n.locationInputErrorMessage;
    final services = context.services;

    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.backgroundPaper,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        // Sheet keeps its saving state until the profile write finishes.
        child: CitySelectorSheet(
          location: null,
          onCitySelected: (location) async {
            if (location == null) return;
            final saved = await cubit.saveLocation(
              profile: profile,
              location: location,
            );
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            if (saved) {
              services.hapticsService.success();
              services.analyticsService.logEvent(name: 'location_prompt_saved');
            } else {
              services.hapticsService.error();
              messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
            }
          },
        ),
      ),
    );
  }

  void _onSkip(BuildContext context) {
    context.hapticsTap();
    context.logEvent(name: 'location_prompt_dismissed');
    context.read<LocationPromptCubit>().dismiss();
  }

  @override
  Widget build(BuildContext context) {
    // Hide the prompt if the profile already has a location.
    if (profile.location != null) return const SizedBox.shrink();

    return BlocProvider<LocationPromptCubit>(
      create: (_) => GetIt.I<LocationPromptCubit>()..load(),
      child: BlocBuilder<LocationPromptCubit, LocationPromptState>(
        builder: (context, state) {
          final Widget? content = switch (state) {
            LocationPromptHidden() => null,
            LocationPromptVisible() => _buildPrompt(context),
            LocationPromptSaved(:final location) =>
              _LocationSavedMessage(cityName: location.name),
          };
          if (content == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignSpec.paddingLg),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.backgroundPaper,
                borderRadius: BorderRadius.circular(DesignSpec.paddingMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(DesignSpec.paddingLg),
                child: AnimatedSize(
                  duration: Durations.medium2,
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: Durations.medium2,
                    child: KeyedSubtree(
                      key: ValueKey(state.runtimeType),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrompt(BuildContext context) {
    final l10n = ProfileLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LocationPitch(),
        Gap.medium(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DialogButton.secondary(
              text: l10n.profileWizardSkip,
              onPressed: () => _onSkip(context),
            ),
            Gap.small(),
            DialogButton.primary(
              text: l10n.locationPromptAction,
              onPressed: () => _onAdd(context),
            ),
          ],
        ),
      ],
    );
  }
}

class const _LocationSavedMessage({required final String cityName})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = ProfileLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.locationSavedTitle,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
          Gap.medium(),
          Text(
            l10n.locationSavedBody(cityName),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.charcoal),
          ),
        ],
      ),
    );
  }
}
