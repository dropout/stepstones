import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_presence/admin_presence.dart';
import 'package:admin_presence/src/domain/entity/admin_presence_entity.dart';
import 'package:admin_presence/src/domain/entity/admin_presence_location_entity.dart';
import 'package:admin_presence/src/domain/enum/admin_presence_window.dart';
import 'package:admin_presence/src/presentation/view/admin_presence_view.dart';
import 'package:admin_presence/src/presentation/viewmodel/admin_presence_cubit.dart';

import '../../admin_presence_mock_definitions.dart';

void main() {
  late MockAdminPresenceCubit cubit;

  final now = DateTime(2026, 11, 14, 12);
  final anna = AdminPresenceEntity(
    profileId: 'anna',
    firstName: 'Anna',
    lastName: 'Kovacs',
    startedAt: now.subtract(const Duration(minutes: 12)),
    locationName: 'Budapest',
  );
  final bela = AdminPresenceEntity(
    profileId: 'bela',
    firstName: 'Bela',
    startedAt: now.subtract(const Duration(hours: 2)),
  );
  final yesterday = AdminPresenceEntity(
    profileId: 'cili',
    firstName: 'Cili',
    startedAt: now.subtract(const Duration(days: 1, hours: 3)),
  );

  AdminPresenceState loaded(
    List<AdminPresenceEntity> entries, {
    AdminPresenceWindow window = AdminPresenceWindow.threeHours,
    bool truncated = false,
  }) => AdminPresenceState.loaded(
    window: window,
    entries: entries,
    locations: const [
      AdminPresenceLocationEntity(name: 'Budapest', count: 1),
      AdminPresenceLocationEntity(name: null, count: 1),
    ],
    now: now,
    truncated: truncated,
  );

  setUpAll(() => registerFallbackValue(AdminPresenceWindow.hour));

  setUp(() {
    cubit = MockAdminPresenceCubit();
    when(() => cubit.start()).thenAnswer((_) async {});
    when(() => cubit.selectWindow(any())).thenAnswer((_) async {});
  });

  Future<void> pumpView(WidgetTester tester, AdminPresenceState state, {Size size = const Size(1200, 800)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    whenListen(cubit, const Stream<AdminPresenceState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AdminPresenceLocalizations.localizationsDelegates,
        supportedLocales: AdminPresenceLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<AdminPresenceCubit>.value(value: cubit, child: const AdminPresenceView()),
        ),
      ),
    );
  }

  testWidgets('shows a progress indicator while loading', (tester) async {
    await pumpView(tester, const AdminPresenceState.loading(window: AdminPresenceWindow.threeHours));
    expect(find.byKey(const Key('admin_presence_loading')), findsOneWidget);
  });

  testWidgets('shows the error view and retries', (tester) async {
    await pumpView(tester, const AdminPresenceState.error(window: AdminPresenceWindow.threeHours));
    expect(find.byKey(const Key('admin_presence_error')), findsOneWidget);
    await tester.tap(find.text('Retry'));
    verify(() => cubit.start()).called(1);
  });

  testWidgets('shows the empty state', (tester) async {
    await pumpView(tester, loaded(const []));
    expect(find.byKey(const Key('admin_presence_empty')), findsOneWidget);
    expect(find.text('0 started practicing in the past 3 hours'), findsOneWidget);
  });

  testWidgets('lists entries with location, age and start time', (tester) async {
    await pumpView(tester, loaded([anna, bela]));

    expect(find.text('2 started practicing in the past 3 hours'), findsOneWidget);
    expect(find.text('Anna Kovacs'), findsOneWidget);
    expect(find.text('12 min ago'), findsOneWidget);
    expect(find.text('11:48'), findsOneWidget);
    expect(find.text('Bela'), findsOneWidget);
    expect(find.text('2 h ago'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.byKey(const Key('admin_presence_truncated')), findsNothing);
  });

  testWidgets('shows the breakdown by location', (tester) async {
    await pumpView(tester, loaded([anna, bela]));

    final locations = find.byKey(const Key('admin_presence_locations'));
    expect(find.descendant(of: locations, matching: find.text('Budapest')), findsOneWidget);
    expect(find.descendant(of: locations, matching: find.text('No location shared')), findsOneWidget);
  });

  testWidgets('shows the date for a start on an earlier day', (tester) async {
    await pumpView(tester, loaded([yesterday], window: AdminPresenceWindow.week));

    expect(find.text('1 d ago'), findsOneWidget);
    expect(find.text('2026-11-13 09:00'), findsOneWidget);
  });

  testWidgets('notes when the list is capped', (tester) async {
    await pumpView(tester, loaded([anna], truncated: true));
    expect(find.text('Only the latest 200 are shown.'), findsOneWidget);
  });

  testWidgets('selecting a window asks the cubit for it', (tester) async {
    await pumpView(tester, loaded([anna]));
    await tester.tap(find.byKey(const Key('admin_presence_window_week')));
    verify(() => cubit.selectWindow(AdminPresenceWindow.week)).called(1);
  });

  testWidgets('fits the smallest window the app allows', (tester) async {
    await pumpView(tester, loaded([anna, bela]), size: const Size(780, 600));
    expect(tester.takeException(), isNull);
  });
}
