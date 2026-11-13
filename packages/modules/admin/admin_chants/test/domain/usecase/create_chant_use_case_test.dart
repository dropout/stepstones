import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/entity/prepared_chant_asset_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/failure/chant_failure.dart';
import 'package:admin_chants/src/domain/usecase/create_chant_use_case.dart';

import '../../admin_chants_mock_definitions.dart';

void main() {
  late MockChantAssetPreparer preparer;
  late MockAdminChantRepository repository;
  late CreateChantUseCase useCase;

  const files = {
    ChantAssetType.audio: '/tmp/a.mp3',
    ChantAssetType.lyrics: '/tmp/a.ass',
    ChantAssetType.cover: '/tmp/a.jpg',
  };
  const existing = [
    AdminChantEntity(id: 'first', name: 'First', order: 0),
    AdminChantEntity(id: 'second', name: 'Second', order: 4),
  ];

  PreparedChantAssetEntity prepared(ChantAssetType type) =>
      PreparedChantAssetEntity(type: type, bytes: Uint8List(1), sha256: type.name);

  Matcher failsWith(ChantFailureReason reason) =>
      throwsA(isA<ChantFailure>().having((failure) => failure.reason, 'reason', reason));

  setUpAll(() {
    registerFallbackValue(prepared(ChantAssetType.audio));
    registerFallbackValue(ChantAssetType.audio);
  });

  setUp(() {
    preparer = MockChantAssetPreparer();
    repository = MockAdminChantRepository();
    useCase = CreateChantUseCase(chantAssetPreparer: preparer, adminChantRepository: repository);
    for (final type in ChantAssetType.values) {
      when(() => preparer.prepare(type, any())).thenAnswer((_) async => prepared(type));
    }
    when(
      () => repository.createChant(
        chantId: any(named: 'chantId'),
        name: any(named: 'name'),
        order: any(named: 'order'),
        audio: any(named: 'audio'),
        lyrics: any(named: 'lyrics'),
        cover: any(named: 'cover'),
      ),
    ).thenAnswer((_) async {});
  });

  test('creates the chant after the last one with a trimmed name', () async {
    await useCase.execute(name: ' Heart Sutra ', chantId: 'heart-sutra', filePaths: files, existingChants: existing);

    verify(
      () => repository.createChant(
        chantId: 'heart-sutra',
        name: 'Heart Sutra',
        order: 5,
        audio: prepared(ChantAssetType.audio),
        lyrics: prepared(ChantAssetType.lyrics),
        cover: prepared(ChantAssetType.cover),
      ),
    ).called(1);
  });

  test('the first chant gets order 0', () async {
    await useCase.execute(name: 'A', chantId: 'a', filePaths: files, existingChants: const []);

    verify(
      () => repository.createChant(
        chantId: 'a',
        name: 'A',
        order: 0,
        audio: any(named: 'audio'),
        lyrics: any(named: 'lyrics'),
        cover: any(named: 'cover'),
      ),
    ).called(1);
  });

  test('rejects invalid input before reading any file', () async {
    Future<void> run({String name = 'Name', String id = 'ok-id', Map<ChantAssetType, String> paths = files}) =>
        useCase.execute(name: name, chantId: id, filePaths: paths, existingChants: existing);

    await expectLater(run(name: '  '), failsWith(.emptyName));
    await expectLater(run(name: 'x' * 101), failsWith(.nameTooLong));
    for (final id in ['', 'Has Space', 'UPPER', '-lead', 'trail-', 'double--dash', 'a/b', 'x' * 65]) {
      await expectLater(run(id: id), failsWith(.invalidId), reason: id);
    }
    await expectLater(run(id: 'second'), failsWith(.duplicateId));
    await expectLater(run(paths: {ChantAssetType.audio: '/tmp/a.mp3'}), failsWith(.missingFile));

    verifyNever(() => preparer.prepare(any(), any()));
  });

  test('does not create the chant when a file cannot be prepared', () async {
    when(() => preparer.prepare(ChantAssetType.cover, any())).thenThrow(const ChantFailure(.unreadableAsset));

    await expectLater(
      useCase.execute(name: 'A', chantId: 'a', filePaths: files, existingChants: existing),
      failsWith(.unreadableAsset),
    );
    verifyNever(
      () => repository.createChant(
        chantId: any(named: 'chantId'),
        name: any(named: 'name'),
        order: any(named: 'order'),
        audio: any(named: 'audio'),
        lyrics: any(named: 'lyrics'),
        cover: any(named: 'cover'),
      ),
    );
  });

  test('suggestId turns a name into a slug', () {
    expect(CreateChantUseCase.suggestId('Heart Sutra'), 'heart-sutra');
    expect(CreateChantUseCase.suggestId('  Om Mani — Padme Hum! '), 'om-mani-padme-hum');
    expect(CreateChantUseCase.suggestId('Ének'), 'nek');
    expect(CreateChantUseCase.suggestId('x' * 80).length, 64);
  });
}
