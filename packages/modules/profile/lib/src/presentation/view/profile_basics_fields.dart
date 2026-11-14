import 'package:profile/l10n/profile_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:core/core.dart';
import 'package:profile/src/presentation/view/form_builder_profile_image_picker.dart';
import 'package:profile/src/public/model/profile.dart';

/// Photo and name inputs; must be placed inside a [FormBuilder].
class ProfileBasicsFields extends StatelessWidget {
  final Profile profile;
  final GlobalKey<FormBuilderState> formStateKey;

  const ProfileBasicsFields({
    required this.profile,
    required this.formStateKey,
    super.key,
  });

  void _showImageErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('error uploading image'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onProfileImagePickerError(
    BuildContext context,
    ProfileImagePickerError errorType,
    dynamic error,
  ) {
    switch (errorType) {
      case ProfileImagePickerError.photoAccessDenied:
        showAppDialog(context, const PhotoAccessDeniedDialog());
        break;
      case ProfileImagePickerError.notSafeImage:
        showAppDialog(context, const ImageUploadNotSafeDialog());
      default:
        _showImageErrorSnackBar(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ProfileLocalizations.of(context).profileImageLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.charcoal,
          ),
        ),
        Gap.xs(),
        FormBuilderProfileImagePicker(
          key: const Key('profile_edit_form_image_picker'),
          name: 'imageData',
          label: ProfileLocalizations.of(context).profileImageLabel,
          profile: profile,
          onError: (errorType, error) =>
              _onProfileImagePickerError(context, errorType, error),
        ),
        Gap.medium(),
        ..._buildNameInputs(context),
      ],
    );
  }

  // First name first or last name first depending on locale
  List<Widget> _buildNameInputs(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    if (locale.languageCode.toLowerCase() == 'hu') {
      return [
        AppTextInput(
          name: 'lastName',
          keyboardType: .name,
          label: ProfileLocalizations.of(context).profileLastnameLabel,
          key: const Key('profile_edit_form_last_name_input'),
          initialValue: profile.lastName,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
          ]),
          onChanged: (_) =>
              formStateKey.currentState?.fields['lastName']?.validate(),
        ),
        Gap.medium(),
        AppTextInput(
          name: 'firstName',
          keyboardType: .name,
          label: ProfileLocalizations.of(context).profileFirstnameLabel,
          key: const Key('profile_edit_form_first_name_input'),
          initialValue: profile.firstName,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
          ]),
          onChanged: (_) =>
              formStateKey.currentState?.fields['firstName']?.validate(),
        ),
      ];
    } else {
      return [
        AppTextInput(
          name: 'firstName',
          label: ProfileLocalizations.of(context).profileFirstnameLabel,
          key: const Key('profile_edit_form_first_name_input'),
          initialValue: profile.firstName,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
          ]),
          onChanged: (_) =>
              formStateKey.currentState?.fields['firstName']?.validate(),
        ),
        Gap.medium(),
        AppTextInput(
          name: 'lastName',
          label: ProfileLocalizations.of(context).profileLastnameLabel,
          key: const Key('profile_edit_form_last_name_input'),
          initialValue: profile.lastName,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
          ]),
          onChanged: (_) =>
              formStateKey.currentState?.fields['lastName']?.validate(),
        ),
      ];
    }
  }
}
