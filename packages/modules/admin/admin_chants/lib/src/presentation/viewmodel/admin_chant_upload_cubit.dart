import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/entity/picked_chant_file_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/failure/chant_failure.dart';
import 'package:admin_chants/src/domain/service/chant_file_picker.dart';
import 'package:admin_chants/src/domain/usecase/create_chant_use_case.dart';

part 'admin_chant_upload_cubit.freezed.dart';

enum AdminChantUploadStatus { editing, uploading, completed }

@freezed
sealed class AdminChantUploadState with _$AdminChantUploadState {
  const AdminChantUploadState._();

  const factory AdminChantUploadState({
    @Default({}) Map<ChantAssetType, PickedChantFileEntity> files,
    @Default(AdminChantUploadStatus.editing) AdminChantUploadStatus status,
    // A user-correctable problem; null with [failed] set means an unexpected error.
    ChantFailureReason? failureReason,
    @Default(false) bool failed,
  }) = _AdminChantUploadState;

  bool get isUploading => status == AdminChantUploadStatus.uploading;
}

class AdminChantUploadCubit extends Cubit<AdminChantUploadState> with LoggerMixin {
  final CreateChantUseCase createChantUseCase;
  final ChantFilePicker chantFilePicker;
  final CrashlyticsService crashlyticsService;

  AdminChantUploadCubit({
    required this.createChantUseCase,
    required this.chantFilePicker,
    required this.crashlyticsService,
  }) : super(const AdminChantUploadState());

  Future<void> pickFile(ChantAssetType type) async {
    if (state.isUploading) return;
    final file = await chantFilePicker.pick(type);
    if (file == null || isClosed) return;
    emit(state.copyWith(files: {...state.files, type: file}, failureReason: null, failed: false));
  }

  Future<void> submit({
    required String name,
    required String chantId,
    required List<AdminChantEntity> existingChants,
  }) async {
    if (state.status != AdminChantUploadStatus.editing) return;
    emit(state.copyWith(status: AdminChantUploadStatus.uploading, failureReason: null, failed: false));
    try {
      await createChantUseCase.execute(
        name: name,
        chantId: chantId.trim(),
        filePaths: {for (final MapEntry(:key, :value) in state.files.entries) key: value.path},
        existingChants: existingChants,
      );
      if (!isClosed) emit(state.copyWith(status: AdminChantUploadStatus.completed));
    } on ChantFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(status: AdminChantUploadStatus.editing, failureReason: failure.reason, failed: true));
      }
    } catch (e, stack) {
      crashlyticsService.recordError(exception: e, stackTrace: stack, reason: 'Unable to upload chant');
      if (!isClosed) emit(state.copyWith(status: AdminChantUploadStatus.editing, failed: true));
    }
  }
}
