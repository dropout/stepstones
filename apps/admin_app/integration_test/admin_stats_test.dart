import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/emulator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an admin sees summed global stats and follows a newly counted session', (tester) async {
    final run = DateTime.now().microsecondsSinceEpoch;
    final password = 'pw-$run';
    final adminEmail = 'admin-$run@example.test';
    await createEmulatorUser(adminEmail, password, admin: true);

    final now = DateTime.now().toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    final today = 'global_stats/daily_${now.year}-${two(now.month)}-${two(now.day)}/shards';
    const allTime = 'global_stats/all_time/shards';
    // Fixed shard ids are overwritten, so earlier runs on the same emulator cannot skew the sums.
    await setEmulatorDocument('$allTime/0', {
      'totalSessions': 5,
      'totalDurationInSeconds': 3000,
      'type_timer': 4,
      'type_chanting': 1,
    });
    await setEmulatorDocument('$allTime/1', {'totalSessions': 2, 'totalDurationInSeconds': 600, 'type_timer': 2});
    await setEmulatorDocument('$today/0', {'totalSessions': 3, 'totalDurationInSeconds': 1800, 'type_timer': 3});

    Finder inCard(String key, String text) => find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

    await launchAdminAppSignedOut(tester);
    await signIn(tester, adminEmail, password);
    await pumpUntil(tester, adminShell);
    await tester.tap(find.byIcon(Icons.insights_outlined));
    await pumpUntil(tester, inCard('admin_stats_all_time', '7 sessions'));
    expect(inCard('admin_stats_all_time', '1 h 0 min practiced'), findsOneWidget);
    expect(inCard('admin_stats_all_time', 'Timer: 6'), findsOneWidget);
    expect(inCard('admin_stats_all_time', 'Chanting: 1'), findsOneWidget);
    await pumpUntil(tester, inCard('admin_stats_today', '3 sessions'));
    expect(inCard('admin_stats_today', '30 min practiced'), findsOneWidget);

    // Mirrors the Cloud Function counting one more session: the day first, then the all-time total.
    await setEmulatorDocument('$today/0', {'totalSessions': 4, 'totalDurationInSeconds': 2400, 'type_timer': 4});
    await setEmulatorDocument('$allTime/1', {'totalSessions': 3, 'totalDurationInSeconds': 1200, 'type_timer': 3});
    await pumpUntil(tester, inCard('admin_stats_all_time', '8 sessions'));
    await pumpUntil(tester, inCard('admin_stats_today', '4 sessions'));

    await tester.tap(find.byKey(const Key('admin_shell_sign_out')));
    await pumpUntil(tester, signInForm);
  });
}
