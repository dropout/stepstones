import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/emulator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an admin renames and reorders chants without touching playCount', (tester) async {
    final run = DateTime.now().microsecondsSinceEpoch;
    final password = 'pw-$run';
    final adminEmail = 'admin-$run@example.test';
    final firstId = 'first-$run';
    final secondId = 'second-$run';
    await createEmulatorUser(adminEmail, password, admin: true);
    await seedEmulatorDocument('chants', firstId, {
      'id': firstId,
      'name': 'First $run',
      'order': 0,
      'length': 125,
      'playCount': 4,
      'blurHash': 'LEHV6nWB2yk8',
      'metaData': {'id': firstId, 'audioVersion': 1, 'audioBytes': 2048},
    });
    // No blurHash and no playCount, like a chant written by the legacy upload script.
    await seedEmulatorDocument('chants', secondId, {'id': secondId, 'name': 'Second $run', 'order': 1, 'length': 60});

    await launchAdminAppSignedOut(tester);
    await signIn(tester, adminEmail, password);
    await pumpUntil(tester, find.text('First $run'));
    expect(find.text('Second $run'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);

    await tester.tap(find.text('First $run'));
    await pumpUntil(tester, find.byKey(const Key('admin_chant_name')));
    await tester.enterText(find.byKey(const Key('admin_chant_name')), 'Renamed $run');
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin_chant_save')));
    await pumpUntilTrue(
      tester,
      () async => (await readEmulatorDocument('chants/$firstId'))['name'] == 'Renamed $run',
      'the rename to reach Firestore',
    );
    expect(find.text('Renamed $run'), findsWidgets);

    // Drives the list's reorder callback directly; a pointer drag is too timing-sensitive here.
    // Positions are looked up because the emulator may hold chants from other tests.
    final tileKeys = [for (final tile in tester.widgetList<ListTile>(find.byType(ListTile))) tile.key];
    final firstIndex = tileKeys.indexOf(ValueKey('admin_chant_$firstId'));
    final secondIndex = tileKeys.indexOf(ValueKey('admin_chant_$secondId'));
    expect(firstIndex, lessThan(secondIndex));
    tester.widget<ReorderableListView>(find.byType(ReorderableListView)).onReorderItem!(firstIndex, secondIndex);

    Future<int> orderOf(String chantId) async => (await readEmulatorDocument('chants/$chantId'))['order']! as int;
    await pumpUntilTrue(
      tester,
      () async => await orderOf(firstId) > await orderOf(secondId),
      'the new order to reach Firestore',
    );

    final first = await readEmulatorDocument('chants/$firstId');
    final second = await readEmulatorDocument('chants/$secondId');
    expect(first['playCount'], 4);
    expect(first['id'], firstId);
    expect(second.containsKey('playCount'), isFalse);

    await tester.tap(find.byKey(const Key('admin_shell_sign_out')));
    await pumpUntil(tester, signInForm);
  });
}
