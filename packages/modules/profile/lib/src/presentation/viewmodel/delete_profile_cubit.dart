import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:profile/src/domain/service/profile_auth_port.dart';
import 'package:profile/src/domain/usecase/delete_profile_use_case.dart';
import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_profile_cubit.freezed.dart';

@freezed
sealed class DeleteProfileState with _$DeleteProfileState {

  const DeleteProfileState._();

  const factory DeleteProfileState.initial() = DeleteProfileInitialState;
  const factory DeleteProfileState.loading() = DeleteProfileLoadingState;
  const factory DeleteProfileState.error() = DeleteProfileErrorState;
  const factory DeleteProfileState.completed() = DeleteProfileCompletedState;
  /// [accountMismatch] is set after the user confirmed with a different account.
  const factory DeleteProfileState.authRequired({@Default(false) bool accountMismatch}) = DeleteProfileAuthRequiredState;

}


class DeleteProfileCubit extends Cubit<DeleteProfileState> with LoggerMixin {

  final DeleteProfileUseCase deleteProfileUseCase;
  final CrashlyticsService crashlyticsService;

  DeleteProfileCubit({
    required this.deleteProfileUseCase,
    required this.crashlyticsService,
  }) : super(const DeleteProfileState.initial());

  Future<void> deleteProfile() => _delete();

  /// Confirms the user's identity with [provider], then deletes the profile.
  Future<void> reauthenticateAndDelete(ReauthProvider provider) => _delete(reauthenticateWith: provider);

  Future<void> _delete({ReauthProvider? reauthenticateWith}) async {
    try {
      logger.t('Deleting user profile...');
      emit(const DeleteProfileState.loading());
      final result = await deleteProfileUseCase.execute(reauthenticateWith: reauthenticateWith);
      // The screen can be popped while deletion runs.
      if (isClosed) return;

      emit(switch (result) {
        DeleteProfileResult.completed => const DeleteProfileState.completed(),
        DeleteProfileResult.authRequired ||
        DeleteProfileResult.reauthenticationCancelled => const DeleteProfileState.authRequired(),
        DeleteProfileResult.accountMismatch => const DeleteProfileState.authRequired(accountMismatch: true),
        DeleteProfileResult.notSignedIn => const DeleteProfileState.error(),
      });
    } catch (e, stack) {
      crashlyticsService.recordError(
        exception: e,
        stackTrace: stack,
        reason: 'Unable to delete user profile!'
      );
      if (!isClosed) emit(const DeleteProfileState.error());
    }
  }

}
