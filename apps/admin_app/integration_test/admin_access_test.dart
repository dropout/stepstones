import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/emulator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('only an account with the admin claim reaches the shell', (tester) async {
    final run = DateTime.now().microsecondsSinceEpoch;
    final password = 'pw-$run';
    final adminEmail = 'admin-$run@example.test';
    final userEmail = 'user-$run@example.test';
    await createEmulatorUser(adminEmail, password, admin: true);
    await createEmulatorUser(userEmail, password, admin: false);

    await launchAdminAppSignedOut(tester);

    await signIn(tester, adminEmail, 'wrong-password');
    await pumpUntil(tester, find.byKey(const Key('admin_sign_in_failed')));

    await signIn(tester, userEmail, password);
    await pumpUntil(tester, unauthorizedView);
    expect(adminShell, findsNothing);
    await tester.tap(find.byKey(const Key('admin_access_secondary')));
    await pumpUntil(tester, signInForm);

    await signIn(tester, adminEmail, password);
    await pumpUntil(tester, adminShell);
    expect(find.text(adminEmail), findsOneWidget);

    await tester.tap(find.byIcon(Icons.people_outline));
    await pumpUntil(tester, find.byIcon(Icons.people));

    await tester.tap(find.byKey(const Key('admin_shell_sign_out')));
    await pumpUntil(tester, signInForm);
  });
}
