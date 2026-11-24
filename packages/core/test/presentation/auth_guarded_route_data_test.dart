import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAuthNavigator extends Mock implements AuthNavigator {}

class _GuardedRoute extends AuthGuardedRouteData {
  const _GuardedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const Text('guarded');
}

void main() {
  late MockAuthStateCubit authCubit;
  late MockServices services;
  late GoRouter router;

  setUp(() {
    authCubit = MockAuthStateCubit();
    services = MockServices();
    final authNavigator = _MockAuthNavigator();
    when(() => authNavigator.loginLocation).thenReturn('/login');
    when(() => services.authNavigator).thenReturn(authNavigator);

    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(path: '/login', builder: (_, _) => const Text('login')),
        GoRouteData.$route(path: '/guarded', factory: (_) => const _GuardedRoute()),
      ],
    );
  });

  tearDown(() => router.dispose());

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<Services>.value(value: services),
        BlocProvider<AuthStateCubit>.value(value: authCubit),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  testWidgets('redirects a signed-out user to login', (tester) async {
    when(() => authCubit.state).thenReturn(const AuthState.signedOut());
    await pumpApp(tester);

    router.go('/guarded');
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.text('guarded'), findsNothing);
  });

  testWidgets('treats an unresolved auth state as signed out', (tester) async {
    when(() => authCubit.state).thenReturn(const AuthState.initial());
    await pumpApp(tester);

    router.go('/guarded');
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('lets a signed-in user through', (tester) async {
    when(() => authCubit.state).thenReturn(const AuthState.signedIn(userId: 'u1'));
    await pumpApp(tester);

    router.go('/guarded');
    await tester.pumpAndSettle();

    expect(find.text('guarded'), findsOneWidget);
  });

  testWidgets('reevaluateTopRedirect moves a signed-out user off a guarded page', (tester) async {
    when(() => authCubit.state).thenReturn(const AuthState.signedIn(userId: 'u1'));
    await pumpApp(tester);
    router.go('/guarded');
    await tester.pumpAndSettle();

    when(() => authCubit.state).thenReturn(const AuthState.signedOut());
    await router.reevaluateTopRedirect(tester.element(find.text('guarded')));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.text('guarded'), findsNothing);
  });

  testWidgets('reevaluateTopRedirect also covers a guarded page opened with push', (tester) async {
    when(() => authCubit.state).thenReturn(const AuthState.signedIn(userId: 'u1'));
    await pumpApp(tester);
    router.push('/guarded');
    await tester.pumpAndSettle();
    expect(find.text('guarded'), findsOneWidget);

    when(() => authCubit.state).thenReturn(const AuthState.signedOut());
    await router.reevaluateTopRedirect(tester.element(find.text('guarded')));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.text('guarded'), findsNothing);
  });

  testWidgets('reevaluateTopRedirect leaves a public page alone', (tester) async {
    when(() => authCubit.state).thenReturn(const AuthState.signedIn(userId: 'u1'));
    await pumpApp(tester);
    await tester.pumpAndSettle();

    when(() => authCubit.state).thenReturn(const AuthState.signedOut());
    await router.reevaluateTopRedirect(tester.element(find.text('home')));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(router.state.uri.toString(), '/');
  });
}
