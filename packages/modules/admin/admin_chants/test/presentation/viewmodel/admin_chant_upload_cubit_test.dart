import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/entity/picked_chant_file_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/failure/chant_failure.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chant_upload_cubit.dart';

import '../../admin_chants_mock_definitions.dart';

void main() {
  late MockCreateChantUseCase createChant;
  late MockChantFilePicker filePicker;
  late MockCrashlyticsService crashlytics;

  const audioFile = PickedChantFileEntity(path: '/tmp/a.mp3', name: 'a.mp3');
  const withAudio = AdminChantUploadState(files: {ChantAssetType.audio: audioFile});
  const existing = [AdminChantEntity(id: 'first', name: 'First')];

  AdminChantUploadCubit buildCubit() => AdminChantUploadCubit(
    createChantUseCase: createChant,
    chantFilePicker: filePicker,
    crashlyticsService: crashlytics,
  );

  void stubCreate(Future<void> Function() answer) => when(
    () => createChant.execute(
      name: any(named: 'name'),
      chantId: any(named: 'chantId'),
      filePaths: any(named: 'filePaths'),
      existingChants: any(named: 'existingChants'),
    ),
  ).thenAnswer((_) => answer());

  setUp(() {
    createChant = MockCreateChantUseCase();
    filePicker = MockChantFilePicker();
    crashlytics = MockCrashlyticsService();
  });

  blocTest<AdminChantUploadCubit, AdminChantUploadState>(
    'pickFile stores the chosen file and clears an earlier failure',
    setUp: () => when(() => filePicker.pick(ChantAssetType.audio)).thenAnswer((_) async => audioFile),
    build: buildCubit,
    seed: () => const AdminChantUploadState(failed: true, failureReason: ChantFailureReason.missingFile),
    act: (cubit) => cubit.pickFile(ChantAssetType.audio),
    expect: () => const [withAudio],
  );

  blocTest<AdminChantUploadCubit, AdminChantUploadState>(
    'pickFile keeps the state when the dialog is cancelled',
    setUp: () => when(() => filePicker.pick(ChantAssetType.cover)).thenAnswer((_) async => null),
    build: buildCubit,
    act: (cubit) => cubit.pickFile(ChantAssetType.cover),
    expect: () => const <AdminChantUploadState>[],
  );

  blocTest<AdminChantUploadCubit, AdminChantUploadState>(
    'submit uploads with the chosen file paths and completes',
    setUp: () => stubCreate(() async {}),
    build: buildCubit,
    seed: () => withAudio,
    act: (cubit) => cubit.submit(name: 'Heart Sutra', chantId: ' heart-sutra ', existingChants: existing),
    expect: () => [
      withAudio.copyWith(status: AdminChantUploadStatus.uploading),
      withAudio.copyWith(status: AdminChantUploadStatus.completed),
    ],
    verify: (_) => verify(
      () => createChant.execute(
        name: 'Heart Sutra',
        chantId: 'heart-sutra',
        filePaths: {ChantAssetType.audio: '/tmp/a.mp3'},
        existingChants: existing,
      ),
    ).called(1),
  );

  blocTest<AdminChantUploadCubit, AdminChantUploadState>(
    'a validation failure returns to editing with its reason and is not reported as a crash',
    setUp: () => stubCreate(() async => throw const ChantFailure(ChantFailureReason.duplicateId)),
    build: buildCubit,
    seed: () => withAudio,
    act: (cubit) => cubit.submit(name: 'First', chantId: 'first', existingChants: existing),
    expect: () => [
      withAudio.copyWith(status: AdminChantUploadStatus.uploading),
      withAudio.copyWith(failed: true, failureReason: ChantFailureReason.duplicateId),
    ],
    verify: (_) => verifyNever(
      () => crashlytics.recordError(
        exception: any(named: 'exception'),
        stackTrace: any(named: 'stackTrace'),
        reason: any(named: 'reason'),
      ),
    ),
  );

  blocTest<AdminChantUploadCubit, AdminChantUploadState>(
    'an unexpected error returns to editing and is recorded',
    setUp: () => stubCreate(() async => throw Exception('network')),
    build: buildCubit,
    seed: () => withAudio,
    act: (cubit) => cubit.submit(name: 'A', chantId: 'a', existingChants: existing),
    expect: () => [withAudio.copyWith(status: AdminChantUploadStatus.uploading), withAudio.copyWith(failed: true)],
    verify: (_) => verify(
      () => crashlytics.recordError(
        exception: any(named: 'exception'),
        stackTrace: any(named: 'stackTrace'),
        reason: any(named: 'reason'),
      ),
    ).called(1),
  );
}
