import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/emulator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an admin sees recent practice starts live and widens the window', (tester) async {
    final run = DateTime.now().microsecondsSinceEpoch;
    final password = 'pw-$run';
    final adminEmail = 'admin-$run@example.test';
    await createEmulatorUser(adminEmail, password, admin: true);

    Future<void> seedPresence(String id, String firstName, Duration age, {String? city}) =>
        seedEmulatorDocument('presence', id, {
          'id': id,
          'profile': {'id': id, 'firstName': firstName, 'lastName': 'Run$run'},
          'startedAt': DateTime.now().subtract(age).millisecondsSinceEpoch,
          if (city != null) 'location': {'name': city, 'geoHash': 'u2mw1q8x'},
        });

    await seedPresence('recent-$run', 'Recent', const Duration(minutes: 5), city: 'City$run');
    await seedPresence('old-$run', 'Old', const Duration(days: 2));

    await launchAdminAppSignedOut(tester);
    await signIn(tester, adminEmail, password);
    await pumpUntil(tester, adminShell);
    await tester.tap(find.text('Presence'));
    await pumpUntil(tester, find.text('Recent Run$run'));
    expect(find.text('Old Run$run'), findsNothing);
    // Once in the list and once in the breakdown by location.
    expect(find.text('City$run'), findsNWidgets(2));

    // Written while the screen is open, so it can only appear through the live listener.
    await seedPresence('live-$run', 'Live', Duration.zero);
    await pumpUntil(tester, find.text('Live Run$run'));

    await tester.tap(find.byKey(const Key('admin_presence_window_week')));
    await pumpUntil(tester, find.text('Old Run$run'));
    expect(find.text('Recent Run$run'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin_shell_sign_out')));
    await pumpUntil(tester, signInForm);
  });
}
