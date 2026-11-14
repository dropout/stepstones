import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_access/admin_access.dart';
import 'package:admin_access/src/presentation/viewmodel/admin_access_cubit.dart';

import '../../admin_access_mock_definitions.dart';

void main() {
  late MockAdminAccessCubit cubit;

  setUp(() {
    cubit = MockAdminAccessCubit();
    when(
      () => cubit.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
    when(() => cubit.recheck()).thenAnswer((_) async {});
    when(() => cubit.signOut()).thenReturn(null);
    when(() => cubit.completeSignOut()).thenAnswer((_) async {});
  });

  Future<void> pumpGate(
    WidgetTester tester,
    AdminAccessState state, {
    Stream<AdminAccessState> stream = const Stream<AdminAccessState>.empty(),
  }) async {
    whenListen(cubit, stream, initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AdminAccessLocalizations.localizationsDelegates,
        supportedLocales: AdminAccessLocalizations.supportedLocales,
        home: BlocProvider<AdminAccessCubit>.value(
          value: cubit,
          child: AdminAccessGateContent(
            builder: (context, account, signOut) => Text('admin area for ${account.email}'),
          ),
        ),
      ),
    );
  }

  testWidgets('shows a progress indicator while checking', (tester) async {
    await pumpGate(tester, const AdminAccessState.checking());
    expect(find.byKey(const Key('admin_access_checking')), findsOneWidget);
    expect(find.textContaining('admin area'), findsNothing);
  });

  testWidgets('submits the sign-in form', (tester) async {
    await pumpGate(tester, const AdminAccessState.signedOut());
    await tester.enterText(find.byKey(const Key('admin_sign_in_email')), 'admin@example.com');
    await tester.enterText(find.byKey(const Key('admin_sign_in_password')), 'secret');
    await tester.tap(find.byKey(const Key('admin_sign_in_submit')));
    verify(() => cubit.signIn(email: 'admin@example.com', password: 'secret')).called(1);
  });

  testWidgets('does not submit an incomplete form', (tester) async {
    await pumpGate(tester, const AdminAccessState.signedOut());
    await tester.tap(find.byKey(const Key('admin_sign_in_submit')));
    verifyNever(
      () => cubit.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows the failure message after a failed sign-in', (tester) async {
    await pumpGate(tester, const AdminAccessState.signedOut(signInFailed: true));
    expect(find.byKey(const Key('admin_sign_in_failed')), findsOneWidget);
  });

  testWidgets('blocks a non-admin account and offers recheck and sign-out', (tester) async {
    await pumpGate(tester, const AdminAccessState.unauthorized(email: 'user@example.com'));
    expect(find.byKey(const Key('admin_access_unauthorized')), findsOneWidget);
    expect(find.textContaining('user@example.com'), findsOneWidget);
    expect(find.textContaining('admin area'), findsNothing);
    await tester.tap(find.text('Check again'));
    await tester.tap(find.text('Sign out'));
    verify(() => cubit.recheck()).called(1);
    verify(() => cubit.signOut()).called(1);
  });

  testWidgets('removes the admin area before the session is ended', (tester) async {
    await pumpGate(
      tester,
      const AdminAccessState.authorized(userId: 'a1', email: 'admin@example.com'),
      stream: Stream.value(const AdminAccessState.signingOut()),
    );
    expect(find.textContaining('admin area'), findsOneWidget);
    // The area is still mounted here, so the session must not have been ended yet.
    when(() => cubit.completeSignOut()).thenAnswer((_) async {
      expect(find.textContaining('admin area'), findsNothing);
    });

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('admin_access_checking')), findsOneWidget);
    verify(() => cubit.completeSignOut()).called(1);
  });

  testWidgets('shows the error view with retry', (tester) async {
    await pumpGate(tester, const AdminAccessState.error());
    expect(find.byKey(const Key('admin_access_error')), findsOneWidget);
    await tester.tap(find.text('Retry'));
    verify(() => cubit.recheck()).called(1);
  });

  testWidgets('renders the admin area for an authorized account', (tester) async {
    await pumpGate(tester, const AdminAccessState.authorized(userId: 'a1', email: 'admin@example.com'));
    expect(find.text('admin area for admin@example.com'), findsOneWidget);
  });
}
