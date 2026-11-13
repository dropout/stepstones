import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_app/bootstrap/admin_flavor.dart';
import 'package:admin_app/bootstrap/run_admin_app.dart';

// Requires the Auth, Firestore and Storage emulators for project demo-stepstones (see docs/commands.md).
const _projectId = 'demo-stepstones';
const _authEmulator = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const _storageEmulator = 'http://127.0.0.1:9199/v0/b/$_projectId.firebasestorage.app/o';
const _firestoreEmulator = 'http://127.0.0.1:8080/v1/projects/$_projectId/databases/(default)/documents';

Future<Map<String, dynamic>> _send(
  String method,
  String url, {
  Map<String, Object?>? body,
  bool asOwner = false,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, Uri.parse(url));
    request.headers.contentType = ContentType.json;
    // The emulators treat this token as an admin that bypasses security rules.
    if (asOwner) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer owner');
    if (body != null) request.write(jsonEncode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) throw StateError('Emulator call failed ($method $url): $text');
    return jsonDecode(text) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

Future<void> createEmulatorUser(String email, String password, {required bool admin}) async {
  final user = await _send(
    'POST',
    '$_authEmulator/accounts:signUp?key=emulator',
    body: {'email': email, 'password': password},
  );
  if (admin) {
    await _send(
      'POST',
      '$_authEmulator/projects/$_projectId/accounts:update',
      asOwner: true,
      body: {
        'localId': user['localId'],
        'customAttributes': jsonEncode({'admin': true}),
      },
    );
  }
}

Map<String, Object?> _encodeFields(Map<String, Object?> data) => {
  for (final MapEntry(:key, :value) in data.entries)
    key: switch (value) {
      int() => {'integerValue': '$value'},
      String() => {'stringValue': value},
      Map<String, Object?>() => {
        'mapValue': {'fields': _encodeFields(value)},
      },
      _ => throw ArgumentError('Unsupported Firestore test value: $value'),
    },
};

Future<void> seedEmulatorDocument(String path, String documentId, Map<String, Object?> data) => _send(
  'POST',
  '$_firestoreEmulator/$path?documentId=$documentId',
  asOwner: true,
  body: {'fields': _encodeFields(data)},
);

Object? _decodeValue(Map<String, dynamic> value) {
  if (value.containsKey('stringValue')) return value['stringValue'];
  if (value.containsKey('integerValue')) return int.parse(value['integerValue'] as String);
  if (value.containsKey('mapValue')) {
    final fields = ((value['mapValue'] as Map<String, dynamic>)['fields'] as Map<String, dynamic>?) ?? const {};
    return {for (final MapEntry(:key, :value) in fields.entries) key: _decodeValue(value as Map<String, dynamic>)};
  }
  return null;
}

/// Reads a document's string, integer and map fields, bypassing security rules.
Future<Map<String, Object?>> readEmulatorDocument(String path) async {
  final document = await _send('GET', '$_firestoreEmulator/$path', asOwner: true);
  final fields = (document['fields'] as Map<String, dynamic>?) ?? const {};
  return {for (final MapEntry(:key, :value) in fields.entries) key: _decodeValue(value as Map<String, dynamic>)};
}

/// Returns the size in bytes of an uploaded object, bypassing security rules.
Future<int> readEmulatorStorageObjectSize(String objectPath) async {
  final metadata = await _send('GET', '$_storageEmulator/${Uri.encodeComponent(objectPath)}', asOwner: true);
  return int.parse(metadata['size'] as String);
}

Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 150; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for $finder');
}

Future<void> pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 150; i++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for $finder to disappear');
}

Future<void> pumpUntilTrue(WidgetTester tester, Future<bool> Function() condition, String description) async {
  for (var i = 0; i < 100; i++) {
    if (await condition()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for $description');
}

final signInForm = find.byKey(const Key('admin_sign_in'));
final adminShell = find.byKey(const Key('admin_shell'));
final unauthorizedView = find.byKey(const Key('admin_access_unauthorized'));

/// Starts the dev flavor and leaves it on the sign-in form, clearing any session persisted by an earlier run.
Future<void> launchAdminAppSignedOut(WidgetTester tester) async {
  // The app routes Flutter errors to Crashlytics; the test binding needs its own handler back.
  final testErrorHandler = FlutterError.onError;
  await runAdminApp(AdminFlavor.dev);
  FlutterError.onError = testErrorHandler;

  await pumpUntil(
    tester,
    find.byWidgetPredicate(
      (widget) =>
          widget.key == const Key('admin_sign_in') ||
          widget.key == const Key('admin_shell') ||
          widget.key == const Key('admin_access_unauthorized'),
    ),
  );
  if (adminShell.evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('admin_shell_sign_out')));
  } else if (unauthorizedView.evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('admin_access_secondary')));
  }
  await pumpUntil(tester, signInForm);
}

Future<void> signIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(const Key('admin_sign_in_email')), email);
  await tester.enterText(find.byKey(const Key('admin_sign_in_password')), password);
  await tester.tap(find.byKey(const Key('admin_sign_in_submit')));
}
