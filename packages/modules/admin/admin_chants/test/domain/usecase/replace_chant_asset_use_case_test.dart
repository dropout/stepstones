import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_chants/src/domain/entity/prepared_chant_asset_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/failure/chant_failure.dart';
import 'package:admin_chants/src/domain/usecase/replace_chant_asset_use_case.dart';

import '../../admin_chants_mock_definitions.dart';

void main() {
  late MockChantAssetPreparer preparer;
  late MockAdminChantRepository repository;
  late ReplaceChantAssetUseCase useCase;

  final asset = PreparedChantAssetEntity(type: ChantAssetType.cover, bytes: Uint8List(1), sha256: 'abc');

  setUpAll(() {
    registerFallbackValue(asset);
    registerFallbackValue(ChantAssetType.audio);
  });

  setUp(() {
    preparer = MockChantAssetPreparer();
    repository = MockAdminChantRepository();
    useCase = ReplaceChantAssetUseCase(chantAssetPreparer: preparer, adminChantRepository: repository);
  });

  test('prepares the file and replaces the asset', () async {
    when(() => preparer.prepare(ChantAssetType.cover, '/tmp/c.jpg')).thenAnswer((_) async => asset);
    when(() => repository.replaceChantAsset(chantId: 'a', asset: asset)).thenAnswer((_) async {});

    await useCase.execute(chantId: 'a', type: ChantAssetType.cover, path: '/tmp/c.jpg');

    verify(() => repository.replaceChantAsset(chantId: 'a', asset: asset)).called(1);
  });

  test('uploads nothing when the file is unusable', () async {
    when(() => preparer.prepare(any(), any())).thenThrow(const ChantFailure(.emptyFile));

    await expectLater(
      useCase.execute(chantId: 'a', type: ChantAssetType.audio, path: '/tmp/a.mp3'),
      throwsA(isA<ChantFailure>()),
    );
    verifyNever(
      () => repository.replaceChantAsset(
        chantId: any(named: 'chantId'),
        asset: any(named: 'asset'),
      ),
    );
  });
}
