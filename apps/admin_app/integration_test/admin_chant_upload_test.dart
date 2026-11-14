// The test swaps the native file dialog for a fake, which needs the module's internal picker contract.
// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:admin_chants/src/domain/entity/picked_chant_file_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/service/chant_file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/emulator.dart';

class _FixtureFilePicker implements ChantFilePicker {
  _FixtureFilePicker(this.files);

  final Map<ChantAssetType, PickedChantFileEntity> files;

  @override
  Future<PickedChantFileEntity?> pick(ChantAssetType type) async => files[type];
}

Future<PickedChantFileEntity> _writeFixture(Directory directory, String name, List<int> bytes) async {
  final file = File('${directory.path}/$name');
  await file.writeAsBytes(bytes);
  return PickedChantFileEntity(path: file.path, name: name);
}

Future<List<int>> _asset(String key) async => (await rootBundle.load(key)).buffer.asUint8List();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an admin uploads a chant and replaces its cover', (tester) async {
    final run = DateTime.now().microsecondsSinceEpoch;
    final password = 'pw-$run';
    final adminEmail = 'admin-$run@example.test';
    final chantId = 'bell-$run';
    await createEmulatorUser(adminEmail, password, admin: true);

    await launchAdminAppSignedOut(tester);

    final directory = await Directory.systemTemp.createTemp('admin_chant_upload');
    addTearDown(() => directory.delete(recursive: true));
    final picker = _FixtureFilePicker({
      ChantAssetType.audio: await _writeFixture(
        directory,
        'bell.mp3',
        await _asset('packages/assets/sounds/small_bell.mp3'),
      ),
      ChantAssetType.lyrics: await _writeFixture(directory, 'bell.ass', '[Script Info]\nTitle: Bell\n'.codeUnits),
      ChantAssetType.cover: await _writeFixture(
        directory,
        'bell.jpg',
        await _asset('packages/assets/images/small_bell.jpg'),
      ),
    });
    GetIt.I.allowReassignment = true;
    GetIt.I.registerSingleton<ChantFilePicker>(picker);

    await signIn(tester, adminEmail, password);
    await pumpUntil(tester, find.byKey(const Key('admin_chants_new')));

    await tester.tap(find.byKey(const Key('admin_chants_new')));
    await pumpUntil(tester, find.byKey(const Key('admin_chant_upload_dialog')));
    await tester.enterText(find.byKey(const Key('admin_chant_upload_name')), 'Bell $run');
    await tester.enterText(find.byKey(const Key('admin_chant_upload_id')), chantId);
    for (final type in ChantAssetType.values) {
      await tester.tap(find.byKey(Key('admin_chant_upload_choose_${type.name}')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('bell.mp3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin_chant_upload_submit')));

    // The dialog closes on success and the new chant arrives through the live list.
    await pumpUntil(tester, find.byKey(ValueKey('admin_chant_$chantId')));
    await pumpUntilGone(tester, find.byKey(const Key('admin_chant_upload_dialog')));

    final created = await readEmulatorDocument('chants/$chantId');
    final createdMeta = created['metaData']! as Map<String, Object?>;
    expect(created['id'], chantId);
    expect(created['name'], 'Bell $run');
    expect(created['length'], greaterThan(0));
    expect((created['blurHash']! as String).length, greaterThan(5));
    expect(created.containsKey('playCount'), isFalse);
    expect(createdMeta['id'], chantId);
    expect(createdMeta['audioVersion'], 1);
    expect(createdMeta['coverVersion'], 1);
    expect((createdMeta['audioSha256']! as String).length, 64);
    for (final type in ChantAssetType.values) {
      expect(
        await readEmulatorStorageObjectSize(type.storagePath(chantId).substring(1)),
        createdMeta['${type.name}Bytes'],
        reason: type.name,
      );
    }

    picker.files[ChantAssetType.cover] = await _writeFixture(
      directory,
      'triangle.jpg',
      await _asset('packages/assets/images/triangle.jpg'),
    );
    await tester.tap(find.byKey(ValueKey('admin_chant_$chantId')));
    await pumpUntil(tester, find.byKey(const Key('admin_chant_replace_cover')));
    await tester.tap(find.byKey(const Key('admin_chant_replace_cover')));
    await pumpUntilTrue(
      tester,
      () async => ((await readEmulatorDocument('chants/$chantId'))['metaData']! as Map)['coverVersion'] == 2,
      'the cover version to be bumped',
    );

    final replaced = await readEmulatorDocument('chants/$chantId');
    final replacedMeta = replaced['metaData']! as Map<String, Object?>;
    expect(replacedMeta['coverSha256'], isNot(createdMeta['coverSha256']));
    expect(replacedMeta['audioVersion'], 1);
    expect(replaced['blurHash'], isNot(created['blurHash']));
    expect(replaced['length'], created['length']);
    expect(
      await readEmulatorStorageObjectSize(ChantAssetType.cover.storagePath(chantId).substring(1)),
      replacedMeta['coverBytes'],
    );

    await tester.tap(find.byKey(const Key('admin_shell_sign_out')));
    await pumpUntil(tester, signInForm);
  });
}
