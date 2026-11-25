import 'dart:typed_data';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import 'package:core/core.dart';
import 'package:profile/src/presentation/viewmodel/profile_image_picker_cubit.dart';
import 'package:profile/src/public/model/profile.dart';
import 'package:profile/src/public/view/profile_image.dart';

Future<XFile?> _pickProfileImageFromGallery() {
  return ImagePicker().pickImage(source: ImageSource.gallery);
}

/// A FormBuilder field that allows users to pick an image for their profile
/// from their device.
/// It displays the selected profile's image.
/// It uses the [ProfileImagePicker] widget internally to
/// handle the image selection.
class FormBuilderProfileImagePicker extends FormBuilderField<Uint8List> {
  /// The profile associated with the image picker.
  final Profile profile;

  /// The label for the image picker.
  final String label;

  final void Function(ProfileImagePickerError, dynamic)? onError;
  final PickProfileImage pickImage;

  FormBuilderProfileImagePicker({
    required this.profile,
    required this.label,
    this.onError,
    this.pickImage = _pickProfileImageFromGallery,
    // From Super
    required super.name,
    super.autovalidateMode = AutovalidateMode.disabled,
    super.enabled,
    super.initialValue,
    super.focusNode,
    super.onSaved,
    super.validator,
    super.onChanged,
    super.valueTransformer,
    super.onReset,
    super.key,
  }) : super(
         builder: (FormFieldState<Uint8List?> field) {
           final state = field as FormBuilderImagePickerState;
           final widget = state.widget;

           return ProfileImagePicker(
             profile: widget.profile,
             label: widget.label,
             imageData: field.value,
             onImageSelected: (value) {
               field.didChange(value);
             },
             onError: widget.onError,
             pickImage: widget.pickImage,
           );
         },
       );

  @override
  FormBuilderImagePickerState createState() => FormBuilderImagePickerState();
}

class FormBuilderImagePickerState
    extends FormBuilderFieldState<FormBuilderProfileImagePicker, Uint8List> {}

/// Provides a [ProfileImagePickerCubit] scoped to the picker, so the
/// memory-heavy safe image detector only lives while the picker is shown.
class ProfileImagePicker extends StatelessWidget {
  final String label;
  final Profile profile;
  final Uint8List? imageData;

  final void Function(Uint8List)? onImageSelected;
  final void Function(ProfileImagePickerError, dynamic)? onError;
  final PickProfileImage pickImage;

  const ProfileImagePicker({
    required this.profile,
    required this.label,
    this.imageData,
    this.onImageSelected,
    this.onError,
    this.pickImage = _pickProfileImageFromGallery,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileImagePickerCubit>(
      create: (_) => GetIt.I.get<ProfileImagePickerCubit>()..initialize(),
      child: ProfileImagePickerContent(
        profile: profile,
        label: label,
        imageData: imageData,
        onImageSelected: onImageSelected,
        onError: onError,
        pickImage: pickImage,
      ),
    );
  }
}

class ProfileImagePickerContent extends StatelessWidget {
  /// The size of the edit indicator that appears on the profile image picker.
  static const double _indicatorSize = 32.0;

  final String label;
  final Profile profile;
  final Uint8List? imageData;

  final void Function(Uint8List)? onImageSelected;
  final void Function(ProfileImagePickerError, dynamic)? onError;
  final PickProfileImage pickImage;

  const ProfileImagePickerContent({
    required this.profile,
    required this.label,
    required this.pickImage,
    this.imageData,
    this.onImageSelected,
    this.onError,
    super.key,
  });

  void _onWidgetTapped(BuildContext context) {
    final cubit = context.read<ProfileImagePickerCubit>();
    final state = cubit.state;
    if (state is ProfileImagePickerReadyState && state.isPicking) {
      return;
    }

    cubit.selectImage(pickImage);
    context.hapticsTap();
  }

  void _onStateChanged(BuildContext context, ProfileImagePickerState state) {
    switch (state) {
      case ProfileImagePickerSelectedState(:final imageData):
        onImageSelected?.call(imageData);
      case ProfileImagePickerFailedState(:final error, :final details):
        onError?.call(error, details);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileImagePickerCubit, ProfileImagePickerState>(
      listenWhen: (_, state) => state is ProfileImagePickerSelectedState || state is ProfileImagePickerFailedState,
      listener: _onStateChanged,
      // One-shot results are followed by ready, so keep the current view.
      buildWhen: (_, state) => state is! ProfileImagePickerSelectedState && state is! ProfileImagePickerFailedState,
      builder: (context, state) {
        return switch (state) {
          ProfileImagePickerInitialState() || ProfileImagePickerLoadingState() => _buildLoading(),
          ProfileImagePickerReadyState(:final isPicking) => _buildLoaded(context, isPicking: isPicking),
          ProfileImagePickerSelectedState() || ProfileImagePickerFailedState() => _buildLoaded(context),
          ProfileImagePickerErrorState() => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      width: DesignSpec.circleLg,
      height: DesignSpec.circleLg,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLoaded(BuildContext context, {bool isPicking = false}) {
    final Offset indicatorPos = _computeEditBadgePosition(45.0);
    return GestureDetector(
      onTap: () => _onWidgetTapped(context),
      child: SizedBox(
        width: DesignSpec.circleLg,
        height: DesignSpec.circleLg,
        child: Stack(
          children: [
            _buildCurrentImage(),

            // Picking can take a while on cold start on some devices.
            if (isPicking)
              SizedBox.expand(
                child: CircularProgressIndicator(
                  strokeWidth: 4.0,
                  color: AppColors.backgroundPaperLight,
                ),
              ),

            Positioned(
              left: indicatorPos.dx,
              top: indicatorPos.dy,
              child: ProfileImagePickerEditBadge(indicatorSize: _indicatorSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentImage() {
    if (imageData != null) {
      return ProfileImagePickerCurrentImage(
        imageProvider: MemoryImage(imageData!),
      );
    }

    return SizedBox.expand(
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 4.0),
        ),
        child: ProfileImage(
          profileId: profile.id,
          profileName: profile.displayName,
          profilePhotoBlurhash: profile.photoBlurhash,
          size: DesignSpec.circleLg,
        ),
      ),
    );
  }

  /// Computes the position of the edit indicator based on the given angle in degrees.
  /// The indicator is positioned on the circumference of the profile image circle.
  Offset _computeEditBadgePosition(double angleDegrees) {
    final double radius =
        DesignSpec.circleLg / 2 - 6.0; // minus the border width
    final double angleRadians = angleDegrees * math.pi / 180.0;
    final double center = DesignSpec.circleLg / 2;
    final double left =
        center + radius * math.cos(angleRadians) - _indicatorSize / 2;
    final double top =
        center + radius * math.sin(angleRadians) - _indicatorSize / 2;
    return Offset(left, top);
  }
}
