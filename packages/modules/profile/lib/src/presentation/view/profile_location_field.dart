import 'package:profile/l10n/profile_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:core/core.dart';
import 'package:profile/src/public/model/profile.dart';

/// City input; must be placed inside a [FormBuilder].
class ProfileLocationField extends StatelessWidget {
  final Profile profile;
  final GlobalKey<FormBuilderState> formStateKey;

  const ProfileLocationField({
    required this.profile,
    required this.formStateKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderCitySelector(
      name: 'location',
      label: ProfileLocalizations.of(context).profileLocationLabel,
      key: const Key('profile_edit_form_location_input'),
      initialValue: profile.location,
      onChanged: (_) => formStateKey.currentState?.fields['location']?.validate(),
    );
  }
}
