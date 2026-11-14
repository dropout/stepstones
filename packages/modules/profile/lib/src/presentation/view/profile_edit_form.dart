import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:core/core.dart';
import 'package:profile/src/presentation/view/profile_basics_fields.dart';
import 'package:profile/src/presentation/view/profile_location_field.dart';
import 'package:profile/src/public/model/profile.dart';


class ProfileEditForm extends StatefulWidget {

  final Profile profile;
  final void Function()? onChanged;
  final GlobalKey<FormBuilderState>? formStateKey;

  const ProfileEditForm({
    required this.profile,
    this.formStateKey,
    this.onChanged,
    super.key
  });

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<ProfileEditForm> {

  late final GlobalKey<FormBuilderState> _formKey;

  @override
  void initState() {
    _formKey = widget.formStateKey ?? GlobalKey<FormBuilderState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      skipDisabled: true,
      onChanged: () => widget.onChanged?.call(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileBasicsFields(profile: widget.profile, formStateKey: _formKey),
          Gap.medium(),
          ProfileLocationField(profile: widget.profile, formStateKey: _formKey),
          Gap.medium(),
        ],
      )
    );
  }

}
