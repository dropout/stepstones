import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import 'package:profile/src/data/mapper/profile_mapper.dart';
import 'package:profile/src/domain/usecase/update_profile_use_case.dart';
import 'package:profile/src/public/model/profile.dart';

part 'location_prompt_cubit.freezed.dart';

@freezed
sealed class LocationPromptState with _$LocationPromptState {
  const factory LocationPromptState.hidden() = LocationPromptHidden;
  const factory LocationPromptState.prompt() = LocationPromptVisible;
  const factory LocationPromptState.saved({required Location location}) =
      LocationPromptSaved;
}

/// Drives the post-session location prompt.
class LocationPromptCubit extends Cubit<LocationPromptState> {
  final SharedPreferencesService preferences;
  final UpdateProfileUseCase updateProfileUseCase;
  final CrashlyticsService crashlyticsService;

  LocationPromptCubit({
    required this.preferences,
    required this.updateProfileUseCase,
    required this.crashlyticsService,
  }) : super(const LocationPromptState.hidden());

  Future<void> load() async {
    final dismissed = await preferences.get<bool>(
      key: SharedPreferencesKey.locationPromptDismissed,
    );
    if (isClosed) return;
    emit(
      dismissed == true
          ? const LocationPromptState.hidden()
          : const LocationPromptState.prompt(),
    );
  }

  Future<void> dismiss() async {
    if (!isClosed) emit(const LocationPromptState.hidden());
    await _persistDismissed();
  }

  /// Saves [location] to [profile] and switches to the thank-you state.
  Future<bool> saveLocation({
    required Profile profile,
    required Location location,
  }) async {
    try {
      await updateProfileUseCase.execute(
        profile: profile.toDomain(),
        updatedFields: {'location': location},
      );
    } catch (exception, stackTrace) {
      crashlyticsService.recordError(
        exception: exception,
        stackTrace: stackTrace,
        reason: 'Unable to save location from prompt: ${profile.id}',
      );
      return false;
    }
    if (!isClosed) emit(LocationPromptState.saved(location: location));
    await _persistDismissed();
    return true;
  }

  Future<void> _persistDismissed() => preferences.set<bool>(
    key: SharedPreferencesKey.locationPromptDismissed,
    value: true,
  );
}
