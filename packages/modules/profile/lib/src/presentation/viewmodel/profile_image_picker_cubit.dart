import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_image_picker_cubit.freezed.dart';

@freezed
sealed class ProfileImagePickerState with _$ProfileImagePickerState {
  const ProfileImagePickerState._();

  const factory ProfileImagePickerState.initial() = ProfileImagePickerInitialState;

  /// The safe image detector is being loaded.
  const factory ProfileImagePickerState.loading() = ProfileImagePickerLoadingState;

  /// The detector is ready; [isPicking] is true while an image is being selected.
  const factory ProfileImagePickerState.ready({@Default(false) bool isPicking}) = ProfileImagePickerReadyState;

  /// One-shot result of a successful selection, followed by [ready].
  const factory ProfileImagePickerState.selected(Uint8List imageData) = ProfileImagePickerSelectedState;

  /// One-shot result of a failed selection, followed by [ready].
  const factory ProfileImagePickerState.failed(ProfileImagePickerError error, [Object? details]) =
      ProfileImagePickerFailedState;

  /// The safe image detector could not be loaded.
  const factory ProfileImagePickerState.error() = ProfileImagePickerErrorState;
}

/// Owns the safe image detector for the lifetime of a profile image picker.
class ProfileImagePickerCubit extends Cubit<ProfileImagePickerState> with LoggerMixin {
  final SafeImageDetectorFactory safeImageDetectorFactory;
  final CrashlyticsService crashlyticsService;

  SafeImageDetector? _safeImageDetector;

  ProfileImagePickerCubit({required this.safeImageDetectorFactory, required this.crashlyticsService})
    : super(const ProfileImagePickerState.initial());

  Future<void> initialize() async {
    emit(const ProfileImagePickerState.loading());
    try {
      final detector = await safeImageDetectorFactory.create();
      // The model holds native memory, release it if the picker is already gone.
      if (isClosed) {
        detector.dispose();
        return;
      }
      _safeImageDetector = detector;
      emit(const ProfileImagePickerState.ready());
    } catch (e, stack) {
      crashlyticsService.recordError(
        exception: e,
        stackTrace: stack,
        reason: 'Failed to initialize safe image detector',
      );
      if (!isClosed) {
        emit(const ProfileImagePickerState.error());
      }
    }
  }

  Future<void> selectImage(PickProfileImage pickImage) async {
    final detector = _safeImageDetector;
    final current = state;
    if (detector == null || current is! ProfileImagePickerReadyState || current.isPicking) {
      return;
    }

    emit(const ProfileImagePickerState.ready(isPicking: true));

    final result = await ProfileImageSelectionController(
      pickImage: pickImage,
      safeImageDetectorService: detector,
    ).selectProfileImage();

    if (isClosed) {
      return;
    }

    if (result.imageData != null) {
      emit(ProfileImagePickerState.selected(result.imageData!));
    } else if (result.error != null) {
      logger.w('Error selecting profile image: ${result.error}');
      emit(ProfileImagePickerState.failed(result.error!, result.details));
    }
    emit(const ProfileImagePickerState.ready());
  }

  @override
  Future<void> close() {
    _safeImageDetector?.dispose();
    _safeImageDetector = null;
    return super.close();
  }
}
