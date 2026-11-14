import 'dart:async';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin_access/src/domain/entity/admin_access_entity.dart';
import 'package:admin_access/src/domain/repository/admin_access_repository.dart';

part 'admin_access_cubit.freezed.dart';

@freezed
sealed class AdminAccessState with _$AdminAccessState {
  const AdminAccessState._();
  const factory AdminAccessState.checking() = AdminAccessCheckingState;
  const factory AdminAccessState.signedOut({@Default(false) bool signInFailed}) = AdminAccessSignedOutState;
  const factory AdminAccessState.signingIn() = AdminAccessSigningInState;
  const factory AdminAccessState.signingOut() = AdminAccessSigningOutState;
  const factory AdminAccessState.unauthorized({String? email}) = AdminAccessUnauthorizedState;
  const factory AdminAccessState.authorized({required String userId, String? email}) = AdminAccessAuthorizedState;
  const factory AdminAccessState.error() = AdminAccessErrorState;
}

class AdminAccessCubit extends Cubit<AdminAccessState> with LoggerMixin {
  final AdminAccessRepository adminAccessRepository;
  final AuthPublicApi authApi;
  final CrashlyticsService crashlyticsService;

  StreamSubscription<AdminAccessEntity>? _accessSub;

  AdminAccessCubit({required this.adminAccessRepository, required this.authApi, required this.crashlyticsService})
    : super(const AdminAccessState.checking());

  void start() {
    _accessSub ??= adminAccessRepository.watchAccess().listen(
      _handleAccess,
      onError: (Object error, StackTrace stackTrace) {
        crashlyticsService.recordError(
          exception: error,
          stackTrace: stackTrace,
          reason: 'Unable to resolve admin access',
        );
        if (!isClosed) emit(const AdminAccessState.error());
      },
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const AdminAccessState.signingIn());
    try {
      // The access stream emits the resulting state once the token is available.
      await authApi.signInWithEmailAndPassword(email: email.trim(), password: password);
    } catch (e, stack) {
      logger.w('Admin sign-in failed', error: e);
      crashlyticsService.recordError(exception: e, stackTrace: stack, reason: 'Unable to sign in to admin');
      if (!isClosed) emit(const AdminAccessState.signedOut(signInFailed: true));
    }
  }

  Future<void> recheck() async {
    emit(const AdminAccessState.checking());
    try {
      final access = await adminAccessRepository.refreshAccess();
      if (!isClosed) _handleAccess(access);
    } catch (e, stack) {
      crashlyticsService.recordError(exception: e, stackTrace: stack, reason: 'Unable to refresh admin access');
      if (!isClosed) emit(const AdminAccessState.error());
    }
  }

  /// Hides the admin area first; the gate calls [completeSignOut] once it is off screen.
  void signOut() {
    if (state is! AdminAccessSigningOutState) emit(const AdminAccessState.signingOut());
  }

  /// Ends the session; runs after the admin area is disposed so its listeners never see a signed-out user.
  Future<void> completeSignOut() async {
    if (state is! AdminAccessSigningOutState) return;
    try {
      // The access stream emits the signed-out state.
      await authApi.signOut();
    } catch (e, stack) {
      crashlyticsService.recordError(exception: e, stackTrace: stack, reason: 'Unable to sign out of admin');
      if (!isClosed) await recheck();
    }
  }

  void _handleAccess(AdminAccessEntity access) {
    if (isClosed) return;
    switch (access.status) {
      case .signedOut:
        // A failed sign-in keeps its message until the next attempt.
        if (state case AdminAccessSignedOutState(signInFailed: true)) return;
        emit(const AdminAccessState.signedOut());
      case .unauthorized:
        emit(AdminAccessState.unauthorized(email: access.email));
      case .authorized:
        emit(AdminAccessState.authorized(userId: access.userId!, email: access.email));
    }
  }

  @override
  Future<void> close() async {
    await _accessSub?.cancel();
    return super.close();
  }
}
