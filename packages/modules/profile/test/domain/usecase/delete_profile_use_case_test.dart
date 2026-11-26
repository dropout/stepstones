import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:profile/src/domain/service/profile_auth_port.dart';
import 'package:profile/src/domain/usecase/delete_profile_use_case.dart';

import '../../profile_mock_definitions.dart';

void main() {
  late MockProfileAuthPort authService;
  late DeleteProfileUseCase useCase;

  setUpAll(() => registerFallbackValue(ReauthProvider.google));

  setUp(() {
    authService = MockProfileAuthPort();

    useCase = DeleteProfileUseCase(authPort: authService);
  });

  group('DeleteProfileUseCase.execute', () {
    test('returns completed when user deletion succeeds', () async {
      when(() => authService.deleteUser()).thenAnswer((_) async {});
      when(() => authService.getAuthenticatedUserId()).thenAnswer((_) async => 'user123');

      final result = await useCase.execute();

      expect(result, DeleteProfileResult.completed);
      verify(() => authService.deleteUser()).called(1);
    });

    test('returns authRequired when deletion requires recent login', () async {
      when(() => authService.getAuthenticatedUserId()).thenAnswer((_) async => 'user123');
      when(() => authService.deleteUser()).thenThrow(Exception('requires-recent-login'));

      final result = await useCase.execute();

      expect(result, DeleteProfileResult.authRequired);
      verify(() => authService.deleteUser()).called(1);
    });

    test('rethrows non-auth-related exceptions', () async {
      final exception = Exception('network-error');
      when(() => authService.getAuthenticatedUserId()).thenAnswer((_) async => 'user123');
      when(() => authService.deleteUser()).thenThrow(exception);

      expect(() => useCase.execute(), throwsA(same(exception)));
      verifyNever(() => authService.deleteUser());
    });

    test('returns notSignedIn without deleting when nobody is signed in', () async {
      when(() => authService.getAuthenticatedUserId()).thenAnswer((_) async => null);

      final result = await useCase.execute(reauthenticateWith: ReauthProvider.google);

      expect(result, DeleteProfileResult.notSignedIn);
      verifyNever(() => authService.reauthenticate(any()));
      verifyNever(() => authService.deleteUser());
    });
  });

  group('DeleteProfileUseCase.execute with reauthentication', () {
    setUp(() {
      when(() => authService.getAuthenticatedUserId()).thenAnswer((_) async => 'user123');
      when(() => authService.deleteUser()).thenAnswer((_) async {});
    });

    test('reauthenticates before deleting the account', () async {
      when(() => authService.reauthenticate(any())).thenAnswer((_) async {});

      final result = await useCase.execute(reauthenticateWith: ReauthProvider.apple);

      expect(result, DeleteProfileResult.completed);
      verifyInOrder([() => authService.reauthenticate(ReauthProvider.apple), () => authService.deleteUser()]);
    });

    test('deletes nothing when the user confirms with a different account', () async {
      when(() => authService.reauthenticate(any())).thenThrow(const ReauthenticationAccountMismatch());

      final result = await useCase.execute(reauthenticateWith: ReauthProvider.google);

      expect(result, DeleteProfileResult.accountMismatch);
      verifyNever(() => authService.deleteUser());
    });

    test('deletes nothing when the user cancels reauthentication', () async {
      when(() => authService.reauthenticate(any())).thenThrow(const ReauthenticationCancelled());

      final result = await useCase.execute(reauthenticateWith: ReauthProvider.google);

      expect(result, DeleteProfileResult.reauthenticationCancelled);
      verifyNever(() => authService.deleteUser());
    });

    test('does not reauthenticate when no provider is given', () async {
      await useCase.execute();

      verifyNever(() => authService.reauthenticate(any()));
    });
  });
}
