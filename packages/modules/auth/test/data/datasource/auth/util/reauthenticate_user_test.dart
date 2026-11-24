import 'package:auth/src/data/datasource/auth/exception.dart';
import 'package:auth/src/data/datasource/auth/util/reauthenticate_user.dart';
import 'package:firebase_provider/firebase_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUser extends Mock implements User {}

class _MockUserCredential extends Mock implements UserCredential {}

void main() {
  final credential = GoogleAuthProvider.credential(idToken: 'token');
  late _MockUser user;

  setUpAll(() => registerFallbackValue(credential));
  setUp(() => user = _MockUser());

  test('reauthenticates the given user with the credential', () async {
    when(() => user.reauthenticateWithCredential(any())).thenAnswer((_) async => _MockUserCredential());

    await reauthenticateUser(user, credential);

    verify(() => user.reauthenticateWithCredential(credential)).called(1);
  });

  test('throws ReauthenticationUserMismatch when another account was chosen', () {
    when(() => user.reauthenticateWithCredential(any())).thenThrow(FirebaseAuthException(code: 'user-mismatch'));

    expect(() => reauthenticateUser(user, credential), throwsA(isA<ReauthenticationUserMismatch>()));
  });

  test('rethrows other Firebase errors', () {
    when(() => user.reauthenticateWithCredential(any()))
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

    expect(
      () => reauthenticateUser(user, credential),
      throwsA(isA<FirebaseAuthException>().having((e) => e.code, 'code', 'network-request-failed')),
    );
  });
}
