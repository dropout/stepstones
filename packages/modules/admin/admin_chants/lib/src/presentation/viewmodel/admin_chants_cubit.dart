import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/repository/admin_chant_repository.dart';
import 'package:admin_chants/src/domain/service/chant_file_picker.dart';
import 'package:admin_chants/src/domain/usecase/replace_chant_asset_use_case.dart';

part 'admin_chants_cubit.freezed.dart';

@freezed
sealed class AdminChantsState with _$AdminChantsState {
  const AdminChantsState._();
  const factory AdminChantsState.loading() = AdminChantsLoadingState;
  const factory AdminChantsState.loaded({
    required List<AdminChantEntity> chants,
    @Default(false) bool saving,
    @Default(false) bool saveFailed,
  }) = AdminChantsLoadedState;
  const factory AdminChantsState.error() = AdminChantsErrorState;
}

class AdminChantsCubit extends Cubit<AdminChantsState> with LoggerMixin {
  static const maxNameLength = 100;

  final AdminChantRepository adminChantRepository;
  final ReplaceChantAssetUseCase replaceChantAssetUseCase;
  final ChantFilePicker chantFilePicker;
  final CrashlyticsService crashlyticsService;

  StreamSubscription<List<AdminChantEntity>>? _chantsSub;

  AdminChantsCubit({
    required this.adminChantRepository,
    required this.replaceChantAssetUseCase,
    required this.chantFilePicker,
    required this.crashlyticsService,
  }) : super(const AdminChantsState.loading());

  Future<void> start() async {
    await _chantsSub?.cancel();
    if (isClosed) return;
    emit(const AdminChantsState.loading());
    _chantsSub = adminChantRepository.watchChants().listen(
      _handleChants,
      onError: (Object error, StackTrace stackTrace) {
        crashlyticsService.recordError(exception: error, stackTrace: stackTrace, reason: 'Unable to load chants');
        if (!isClosed) emit(const AdminChantsState.error());
      },
    );
  }

  Future<void> rename({required String chantId, required String name}) async {
    final current = state;
    final trimmed = name.trim();
    if (current is! AdminChantsLoadedState || current.saving) return;
    if (trimmed.isEmpty || trimmed.length > maxNameLength) return;

    await _save(current, () => adminChantRepository.renameChant(chantId: chantId, name: trimmed), 'rename chant');
  }

  /// Moves the chant at [fromIndex] so that it ends up at [toIndex] of the resulting list.
  Future<void> reorder({required int fromIndex, required int toIndex}) async {
    final current = state;
    if (current is! AdminChantsLoadedState || current.saving) return;
    final count = current.chants.length;
    if (fromIndex == toIndex || fromIndex < 0 || fromIndex >= count || toIndex < 0 || toIndex >= count) return;

    final reordered = [...current.chants];
    reordered.insert(toIndex, reordered.removeAt(fromIndex));

    // Shown immediately so the list does not snap back while the write is in flight.
    await _save(
      current,
      () => adminChantRepository.reorderChants([for (final chant in reordered) chant.id]),
      'reorder chants',
      optimisticChants: reordered,
    );
  }

  /// Asks for a file and replaces the chant's asset of [type] with it.
  Future<void> replaceAsset({required String chantId, required ChantAssetType type}) async {
    if (state case AdminChantsLoadedState(saving: false)) {
      final file = await chantFilePicker.pick(type);
      final current = state;
      if (file == null || isClosed || current is! AdminChantsLoadedState || current.saving) return;

      await _save(
        current,
        () => replaceChantAssetUseCase.execute(chantId: chantId, type: type, path: file.path),
        'replace chant ${type.name}',
      );
    }
  }

  void dismissSaveFailure() {
    final current = state;
    if (current is AdminChantsLoadedState && current.saveFailed) {
      emit(current.copyWith(saveFailed: false));
    }
  }

  Future<void> _save(
    AdminChantsLoadedState previous,
    Future<void> Function() write,
    String action, {
    List<AdminChantEntity>? optimisticChants,
  }) async {
    emit(previous.copyWith(chants: optimisticChants ?? previous.chants, saving: true, saveFailed: false));
    try {
      await write();
      if (isClosed) return;
      final latest = state;
      if (latest is AdminChantsLoadedState) emit(latest.copyWith(saving: false));
    } catch (e, stack) {
      crashlyticsService.recordError(exception: e, stackTrace: stack, reason: 'Unable to $action');
      if (!isClosed) emit(previous.copyWith(saving: false, saveFailed: true));
    }
  }

  void _handleChants(List<AdminChantEntity> chants) {
    if (isClosed) return;
    final current = state;
    emit(
      current is AdminChantsLoadedState ? current.copyWith(chants: chants) : AdminChantsState.loaded(chants: chants),
    );
  }

  @override
  Future<void> close() async {
    await _chantsSub?.cancel();
    return super.close();
  }
}
