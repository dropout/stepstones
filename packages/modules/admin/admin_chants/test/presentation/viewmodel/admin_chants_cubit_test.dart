import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/entity/picked_chant_file_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chants_cubit.dart';

import '../../admin_chants_mock_definitions.dart';

void main() {
  late MockAdminChantRepository repository;
  late MockReplaceChantAssetUseCase replaceChantAsset;
  late MockChantFilePicker filePicker;
  late MockCrashlyticsService crashlytics;
  late StreamController<List<AdminChantEntity>> chantsController;

  const a = AdminChantEntity(id: 'a', name: 'A', order: 0);
  const b = AdminChantEntity(id: 'b', name: 'B', order: 1);
  const c = AdminChantEntity(id: 'c', name: 'C', order: 2);
  const loaded = AdminChantsLoadedState(chants: [a, b, c]);

  AdminChantsCubit buildCubit() => AdminChantsCubit(
    adminChantRepository: repository,
    replaceChantAssetUseCase: replaceChantAsset,
    chantFilePicker: filePicker,
    crashlyticsService: crashlytics,
  );

  void verifyErrorRecorded() => verify(
    () => crashlytics.recordError(
      exception: any(named: 'exception'),
      stackTrace: any(named: 'stackTrace'),
      reason: any(named: 'reason'),
    ),
  ).called(1);

  setUp(() {
    repository = MockAdminChantRepository();
    replaceChantAsset = MockReplaceChantAssetUseCase();
    filePicker = MockChantFilePicker();
    crashlytics = MockCrashlyticsService();
    chantsController = StreamController<List<AdminChantEntity>>.broadcast();
    when(() => repository.watchChants()).thenAnswer((_) => chantsController.stream);
  });

  tearDown(() => chantsController.close());

  blocTest<AdminChantsCubit, AdminChantsState>(
    'start loads chants and follows later changes',
    build: buildCubit,
    act: (cubit) async {
      await cubit.start();
      chantsController
        ..add([a, b])
        ..add([a, b, c]);
    },
    expect: () => const [
      AdminChantsState.loading(),
      AdminChantsState.loaded(chants: [a, b]),
      AdminChantsState.loaded(chants: [a, b, c]),
    ],
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'emits error and records it when the chants stream fails',
    build: buildCubit,
    act: (cubit) async {
      await cubit.start();
      chantsController.addError(Exception('denied'));
    },
    expect: () => const [AdminChantsState.loading(), AdminChantsState.error()],
    verify: (_) => verifyErrorRecorded(),
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'rename trims the name and toggles saving',
    setUp: () => when(() => repository.renameChant(chantId: 'b', name: 'Renamed')).thenAnswer((_) async {}),
    build: buildCubit,
    seed: () => loaded,
    act: (cubit) => cubit.rename(chantId: 'b', name: '  Renamed '),
    expect: () => [loaded.copyWith(saving: true), loaded],
    verify: (_) => verify(() => repository.renameChant(chantId: 'b', name: 'Renamed')).called(1),
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'rename ignores empty and overlong names',
    build: buildCubit,
    seed: () => loaded,
    act: (cubit) async {
      await cubit.rename(chantId: 'b', name: '   ');
      await cubit.rename(chantId: 'b', name: 'x' * (AdminChantsCubit.maxNameLength + 1));
    },
    expect: () => const <AdminChantsState>[],
    verify: (_) => verifyNever(
      () => repository.renameChant(
        chantId: any(named: 'chantId'),
        name: any(named: 'name'),
      ),
    ),
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'rename failure flags saveFailed and records the error',
    setUp: () => when(
      () => repository.renameChant(
        chantId: any(named: 'chantId'),
        name: any(named: 'name'),
      ),
    ).thenThrow(Exception('denied')),
    build: buildCubit,
    seed: () => loaded,
    act: (cubit) => cubit.rename(chantId: 'b', name: 'Renamed'),
    expect: () => [loaded.copyWith(saving: true), loaded.copyWith(saveFailed: true)],
    verify: (_) => verifyErrorRecorded(),
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'reorder shows the new order immediately and persists the id sequence',
    setUp: () => when(() => repository.reorderChants(any())).thenAnswer((_) async {}),
    build: buildCubit,
    seed: () => loaded,
    act: (cubit) => cubit.reorder(fromIndex: 0, toIndex: 2),
    expect: () => const [
      AdminChantsState.loaded(chants: [b, c, a], saving: true),
      AdminChantsState.loaded(chants: [b, c, a]),
    ],
    verify: (_) => verify(() => repository.reorderChants(['b', 'c', 'a'])).called(1),
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'reorder failure restores the previous order',
    setUp: () => when(() => repository.reorderChants(any())).thenThrow(Exception('denied')),
    build: buildCubit,
    seed: () => loaded,
    act: (cubit) => cubit.reorder(fromIndex: 2, toIndex: 0),
    expect: () => [
      const AdminChantsState.loaded(chants: [c, a, b], saving: true),
      loaded.copyWith(saveFailed: true),
    ],
    verify: (_) => verifyErrorRecorded(),
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'reorder ignores no-op and out-of-range moves',
    build: buildCubit,
    seed: () => loaded,
    act: (cubit) async {
      await cubit.reorder(fromIndex: 1, toIndex: 1);
      await cubit.reorder(fromIndex: 0, toIndex: 3);
      await cubit.reorder(fromIndex: -1, toIndex: 0);
    },
    expect: () => const <AdminChantsState>[],
    verify: (_) => verifyNever(() => repository.reorderChants(any())),
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'replaceAsset replaces the asset with the picked file',
    setUp: () {
      when(() => filePicker.pick(ChantAssetType.audio))
          .thenAnswer((_) async => const PickedChantFileEntity(path: '/tmp/new.mp3', name: 'new.mp3'));
      when(() => replaceChantAsset.execute(chantId: 'b', type: ChantAssetType.audio, path: '/tmp/new.mp3'))
          .thenAnswer((_) async {});
    },
    build: buildCubit,
    seed: () => loaded,
    act: (cubit) => cubit.replaceAsset(chantId: 'b', type: ChantAssetType.audio),
    expect: () => [loaded.copyWith(saving: true), loaded],
    verify: (_) =>
        verify(() => replaceChantAsset.execute(chantId: 'b', type: ChantAssetType.audio, path: '/tmp/new.mp3'))
            .called(1),
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'replaceAsset does nothing when the file dialog is cancelled',
    setUp: () => when(() => filePicker.pick(ChantAssetType.cover)).thenAnswer((_) async => null),
    build: buildCubit,
    seed: () => loaded,
    act: (cubit) => cubit.replaceAsset(chantId: 'b', type: ChantAssetType.cover),
    expect: () => const <AdminChantsState>[],
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'replaceAsset failure flags saveFailed and records the error',
    setUp: () {
      when(() => filePicker.pick(ChantAssetType.lyrics))
          .thenAnswer((_) async => const PickedChantFileEntity(path: '/tmp/new.ass', name: 'new.ass'));
      when(
        () => replaceChantAsset.execute(
          chantId: any(named: 'chantId'),
          type: ChantAssetType.lyrics,
          path: any(named: 'path'),
        ),
      ).thenThrow(Exception('denied'));
    },
    build: buildCubit,
    seed: () => loaded,
    act: (cubit) => cubit.replaceAsset(chantId: 'b', type: ChantAssetType.lyrics),
    expect: () => [loaded.copyWith(saving: true), loaded.copyWith(saveFailed: true)],
    verify: (_) => verifyErrorRecorded(),
  );

  blocTest<AdminChantsCubit, AdminChantsState>(
    'dismissSaveFailure clears the flag',
    build: buildCubit,
    seed: () => loaded.copyWith(saveFailed: true),
    act: (cubit) => cubit.dismissSaveFailure(),
    expect: () => [loaded],
  );

  test('close cancels the chants subscription', () async {
    final cubit = buildCubit();
    await cubit.start();
    expect(chantsController.hasListener, isTrue);
    await cubit.close();
    expect(chantsController.hasListener, isFalse);
  });
}
