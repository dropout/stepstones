import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_app/bootstrap/admin_flavor.dart';
import 'package:admin_app/bootstrap/run_admin_app.dart';

// Requires the Auth, Firestore and Storage emulators for project demo-stepstones (see docs/commands.md).
const _authEmulator = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const _projectId = 'demo-stepstones';

Future<Map<String, dynamic>> _post(String url, Map<String, Object?> body, {bool asOwner = false}) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers.contentType = ContentType.json;
    if (asOwner) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer owner');
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) throw StateError('Auth emulator call failed: $text');
    return jsonDecode(text) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<void> _createUser(String email, String password, {required bool admin}) async {
  final user = await _post('$_authEmulator/accounts:signUp?key=emulator', {'email': email, 'password': password});
  if (admin) {
    await _post('$_authEmulator/projects/$_projectId/accounts:update', {
      'localId': user['localId'],
      'customAttributes': jsonEncode({'admin': true}),
    }, asOwner: true);
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 150; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for $finder');
}

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(const Key('admin_sign_in_email')), email);
  await tester.enterText(find.byKey(const Key('admin_sign_in_password')), password);
  await tester.tap(find.byKey(const Key('admin_sign_in_submit')));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('only an account with the admin claim reaches the shell', (tester) async {
    final run = DateTime.now().microsecondsSinceEpoch;
    final password = 'pw-$run';
    final adminEmail = 'admin-$run@example.test';
    final userEmail = 'user-$run@example.test';
    await _createUser(adminEmail, password, admin: true);
    await _createUser(userEmail, password, admin: false);

    final signInForm = find.byKey(const Key('admin_sign_in'));
    final shell = find.byKey(const Key('admin_shell'));
    final unauthorized = find.byKey(const Key('admin_access_unauthorized'));

    // The app routes Flutter errors to Crashlytics; the test binding needs its own handler back.
    final testErrorHandler = FlutterError.onError;
    await runAdminApp(AdminFlavor.dev);
    FlutterError.onError = testErrorHandler;
    await _pumpUntil(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w.key == const Key('admin_sign_in') ||
            w.key == const Key('admin_shell') ||
            w.key == const Key('admin_access_unauthorized'),
      ),
    );

    // A session persisted by an earlier run is cleared first.
    if (shell.evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('admin_shell_sign_out')));
    } else if (unauthorized.evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('admin_access_secondary')));
    }
    await _pumpUntil(tester, signInForm);

    await _signIn(tester, adminEmail, 'wrong-password');
    await _pumpUntil(tester, find.byKey(const Key('admin_sign_in_failed')));

    await _signIn(tester, userEmail, password);
    await _pumpUntil(tester, unauthorized);
    expect(shell, findsNothing);
    await tester.tap(find.byKey(const Key('admin_access_secondary')));
    await _pumpUntil(tester, signInForm);

    await _signIn(tester, adminEmail, password);
    await _pumpUntil(tester, shell);
    expect(find.text(adminEmail), findsOneWidget);

    await tester.tap(find.byIcon(Icons.people_outline));
    await _pumpUntil(tester, find.byIcon(Icons.people));

    await tester.tap(find.byKey(const Key('admin_shell_sign_out')));
    await _pumpUntil(tester, signInForm);
  });
}
