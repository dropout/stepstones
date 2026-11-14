import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import 'package:core/core.dart';
import 'package:profile/src/data/mapper/profile_mapper.dart';
import 'package:profile/src/domain/usecase/reset_onboarding_use_case.dart';
import 'package:profile/src/presentation/view/settings/profile_settings_button.dart';
import 'package:profile/src/public/model/profile.dart';

/// Debug-only; not localized on purpose.
class ProfileSettingsResetOnboarding extends StatefulWidget {
  final Profile profile;

  const ProfileSettingsResetOnboarding({required this.profile, super.key});

  @override
  State<ProfileSettingsResetOnboarding> createState() =>
      _ProfileSettingsResetOnboardingState();
}

class _ProfileSettingsResetOnboardingState
    extends State<ProfileSettingsResetOnboarding> {
  ProcessingState _state = ProcessingState.idle;

  Future<void> _onTap() async {
    if (_state == ProcessingState.processing) return;
    setState(() => _state = ProcessingState.processing);
    try {
      await GetIt.I<ResetOnboardingUseCase>().execute(
        widget.profile.toDomain(),
      );
      if (mounted) setState(() => _state = ProcessingState.completed);
    } catch (_) {
      if (mounted) setState(() => _state = ProcessingState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSettingsButton(
      text: switch (_state) {
        .processing => 'Resetting…',
        .completed => 'Onboarding reset',
        _ => 'Reset onboarding (debug)',
      },
      helperText:
          'Marks the profile incomplete, clears the city and the '
          'location prompt dismissal. Restart the app to see it.',
      onTap: _onTap,
    );
  }
}
