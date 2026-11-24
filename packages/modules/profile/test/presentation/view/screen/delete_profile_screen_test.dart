import 'package:auth/auth.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:profile/src/domain/service/profile_auth_port.dart';
import 'package:profile/src/presentation/view/screen/delete_profile_screen.dart';
import 'package:profile/src/presentation/viewmodel/delete_profile_cubit.dart';
import 'package:provider/provider.dart';

import '../../../profile_test_helper.dart';

class _MockDeleteProfileCubit extends MockCubit<DeleteProfileState> implements DeleteProfileCubit {}

void main() {
  late _MockDeleteProfileCubit cubit;
  late MockServices services;
  late MockAuthStateCubit authCubit;

  setUpAll(() => registerFallbackValue(ReauthProvider.google));

  setUp(() {
    cubit = _MockDeleteProfileCubit();
    services = MockServices();
    authCubit = MockAuthStateCubit();
    final analytics = MockAnalyticsService();
    when(() => services.analyticsService).thenReturn(analytics);
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    when(() => cubit.reauthenticateAndDelete(any())).thenAnswer((_) async {});
    when(() => authCubit.state).thenReturn(const AuthState.signedIn(userId: 'u1'));
  });

  Future<void> pump(WidgetTester tester, DeleteProfileState state) {
    when(() => cubit.state).thenReturn(state);
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<Services>.value(value: services),
          BlocProvider<AuthStateCubit>.value(value: authCubit),
          BlocProvider<DeleteProfileCubit>.value(value: cubit),
        ],
        child: MaterialApp(
          locale: const Locale('en', 'EN'),
          localizationsDelegates: [...ProfileTestHelper.getProfileLocalizationDelegates(), AuthLocalizations.delegate],
          supportedLocales: const [Locale('en', 'EN'), Locale('hu', 'HU')],
          home: const DeleteProfileScreenContent(),
        ),
      ),
    );
  }

  testWidgets('reauthenticates through the delete cubit, not the app-wide sign-in', (tester) async {
    await pump(tester, const DeleteProfileState.authRequired());

    await tester.tap(find.text(AuthLocalizations.of(tester.element(find.byType(Scaffold))).loginSigninGoogle));
    await tester.pump();

    verify(() => cubit.reauthenticateAndDelete(ReauthProvider.google)).called(1);
    verifyNever(() => authCubit.signinWithGoogle(onComplete: any(named: 'onComplete')));
  });

  testWidgets('explains an account mismatch', (tester) async {
    await pump(tester, const DeleteProfileState.authRequired(accountMismatch: true));

    expect(find.byKey(const Key('delete_profile_account_mismatch')), findsOneWidget);
  });

  testWidgets('hides the mismatch message on the first prompt', (tester) async {
    await pump(tester, const DeleteProfileState.authRequired());

    expect(find.byKey(const Key('delete_profile_account_mismatch')), findsNothing);
  });
}
