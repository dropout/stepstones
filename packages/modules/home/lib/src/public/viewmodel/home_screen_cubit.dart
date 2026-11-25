import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:home/src/public/enum/home_screen_view_state.dart';

part 'home_screen_cubit.freezed.dart';

@freezed
sealed class HomeScreenState with _$HomeScreenState {
  const HomeScreenState._();
  const factory HomeScreenState({
    @Default(HomeScreenViewState.sitting) HomeScreenViewState preferredSessionType,

    /// `null` until the first auth event arrives.
    bool? isSignedIn,
  }) = _HomeScreenState;

  /// The session type to display; signed-out users can only practice sitting.
  // Unknown auth falls back to the preference so signed-in users don't see a sitting flash on startup.
  HomeScreenViewState get sessionType => (isSignedIn == false) ? .sitting : preferredSessionType;
}

class HomeScreenCubit extends HydratedCubit<HomeScreenState> with LoggerMixin {
  final HomeScreenState? initialState;
  final AuthPublicApi authPublicApi;
  final CrashlyticsService crashlyticsService;

  StreamSubscription<AuthSession>? _authSessionSub;

  HomeScreenCubit({this.initialState, required this.authPublicApi, required this.crashlyticsService})
    : super(initialState ?? HomeScreenState()) {
    _authSessionSub = authPublicApi.authSessionStream.listen(
      (session) => emit(state.copyWith(isSignedIn: session.isAuthenticated)),
      onError: (Object error, StackTrace stackTrace) {
        crashlyticsService.recordError(
          exception: error,
          stackTrace: stackTrace,
          reason: 'Error occured when receiving event from auth session stream in HomeScreenCubit',
        );
      },
    );
  }

  @override
  HomeScreenState? fromJson(Map<String, dynamic> json) {
    try {
      if (initialState != null) {
        logger.t('Using initial state for HomeScreenCubit: $initialState');
        return initialState;
      } else {
        // Key kept as 'sessionType' for compatibility with already persisted state.
        final preferredSessionType = HomeScreenViewState.values.byName(json['sessionType'] as String);
        logger.t('Restored HomeScreenCubit state from JSON: $preferredSessionType');
        return HomeScreenState(preferredSessionType: preferredSessionType);
      }
    } catch (e, stack) {
      crashlyticsService.recordError(
        exception: e,
        stackTrace: stack,
        reason: 'Failed to deserialize HomeScreenState from JSON',
      );
      return null;
    }
  }

  @override
  Map<String, dynamic> toJson(HomeScreenState state) {
    logger.t('Saving HomeScreenCubit state: $state');
    return {'sessionType': state.preferredSessionType.name};
  }

  Future<void> setSessionType(HomeScreenViewState sessionType) async {
    try {
      final updatedState = state.copyWith(preferredSessionType: sessionType);
      emit(updatedState);
      logger.t('New session type has been set: $sessionType');
    } catch (e, stackTrace) {
      crashlyticsService.recordError(
        exception: e,
        stackTrace: stackTrace,
        reason: 'Failed to update session type and save HomeScreenState to SharedPreferences',
      );
    }
  }

  @override
  Future<void> close() async {
    await _authSessionSub?.cancel();
    return super.close();
  }
}
