import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_stats/admin_stats.dart';
import 'package:admin_stats/src/domain/entity/daily_global_stats_entity.dart';
import 'package:admin_stats/src/domain/entity/global_stats_entity.dart';
import 'package:admin_stats/src/domain/enum/admin_stats_range.dart';
import 'package:admin_stats/src/presentation/view/admin_stats_view.dart';
import 'package:admin_stats/src/presentation/viewmodel/admin_stats_cubit.dart';

import '../../admin_stats_mock_definitions.dart';

void main() {
  late MockAdminStatsCubit cubit;

  const allTime = GlobalStatsEntity(
    totalSessions: 120,
    totalDuration: Duration(hours: 40, minutes: 5),
    sessionsByType: {'timer': 100, 'chanting': 20},
  );
  final days = [
    DailyGlobalStatsEntity(day: DateTime.utc(2026, 11, 12), stats: const GlobalStatsEntity()),
    DailyGlobalStatsEntity(
      day: DateTime.utc(2026, 11, 13),
      stats: const GlobalStatsEntity(totalSessions: 4, totalDuration: Duration(minutes: 95)),
    ),
    DailyGlobalStatsEntity(
      day: DateTime.utc(2026, 11, 14),
      stats: const GlobalStatsEntity(totalSessions: 2, totalDuration: Duration(minutes: 30)),
    ),
  ];

  AdminStatsState loaded({
    GlobalStatsEntity allTime = allTime,
    AdminStatsDailyStatus dailyStatus = AdminStatsDailyStatus.loaded,
    List<DailyGlobalStatsEntity>? days,
  }) => AdminStatsState.loaded(
    allTime: allTime,
    range: AdminStatsRange.week,
    dailyStatus: dailyStatus,
    days: days ?? const [],
  );

  setUpAll(() => registerFallbackValue(AdminStatsRange.week));

  setUp(() {
    cubit = MockAdminStatsCubit();
    when(() => cubit.start()).thenAnswer((_) async {});
    when(() => cubit.refresh()).thenAnswer((_) async {});
    when(() => cubit.selectRange(any())).thenAnswer((_) async {});
  });

  Future<void> pumpView(WidgetTester tester, AdminStatsState state, {Size size = const Size(1200, 800)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    whenListen(cubit, const Stream<AdminStatsState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AdminStatsLocalizations.localizationsDelegates,
        supportedLocales: AdminStatsLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<AdminStatsCubit>.value(value: cubit, child: const AdminStatsView()),
        ),
      ),
    );
  }

  Finder inCard(String key, String text) => find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

  testWidgets('shows a progress indicator while loading', (tester) async {
    await pumpView(tester, const AdminStatsState.loading());
    expect(find.byKey(const Key('admin_stats_loading')), findsOneWidget);
  });

  testWidgets('shows the error view and retries', (tester) async {
    await pumpView(tester, const AdminStatsState.error());
    expect(find.byKey(const Key('admin_stats_error')), findsOneWidget);
    await tester.tap(find.text('Retry'));
    verify(() => cubit.start()).called(1);
  });

  testWidgets('shows all-time, today and range totals', (tester) async {
    await pumpView(tester, loaded(days: days));

    expect(inCard('admin_stats_all_time', '120 sessions'), findsOneWidget);
    expect(inCard('admin_stats_all_time', '40 h 5 min practiced'), findsOneWidget);
    expect(inCard('admin_stats_all_time', 'Timer: 100'), findsOneWidget);
    expect(inCard('admin_stats_all_time', 'Chanting: 20'), findsOneWidget);
    expect(inCard('admin_stats_today', '2 sessions'), findsOneWidget);
    expect(inCard('admin_stats_today', '30 min practiced'), findsOneWidget);
    expect(inCard('admin_stats_range', '6 sessions'), findsOneWidget);
    expect(inCard('admin_stats_range', '2 h 5 min practiced'), findsOneWidget);
    expect(find.byKey(const Key('admin_stats_empty')), findsNothing);
  });

  testWidgets('lists only days with sessions, newest first', (tester) async {
    await pumpView(tester, loaded(days: days));

    final table = find.byKey(const Key('admin_stats_table'));
    expect(find.descendant(of: table, matching: find.text('2026-11-12')), findsNothing);
    final newest = tester.getTopLeft(find.descendant(of: table, matching: find.text('2026-11-14')));
    final older = tester.getTopLeft(find.descendant(of: table, matching: find.text('2026-11-13')));
    expect(newest.dy, lessThan(older.dy));
    expect(find.descendant(of: table, matching: find.text('1 h 35 min')), findsOneWidget);
    expect(find.byKey(const Key('admin_stats_bars')), findsOneWidget);
  });

  testWidgets('shows placeholders while the daily history loads', (tester) async {
    await pumpView(tester, loaded(dailyStatus: AdminStatsDailyStatus.loading));

    expect(inCard('admin_stats_all_time', '120 sessions'), findsOneWidget);
    expect(inCard('admin_stats_today', '–'), findsOneWidget);
    expect(find.text('Loading daily history…'), findsOneWidget);
    expect(find.byKey(const Key('admin_stats_daily_loading')), findsOneWidget);
    expect(tester.widget<IconButton>(find.byKey(const Key('admin_stats_refresh'))).onPressed, isNull);
  });

  testWidgets('reports a failed daily load', (tester) async {
    await pumpView(tester, loaded(dailyStatus: AdminStatsDailyStatus.failed));
    expect(find.byKey(const Key('admin_stats_daily_failed')), findsOneWidget);
  });

  testWidgets('explains an empty aggregate', (tester) async {
    await pumpView(tester, loaded(allTime: const GlobalStatsEntity(), days: days));
    expect(find.byKey(const Key('admin_stats_empty')), findsOneWidget);
  });

  testWidgets('refresh and range selection reach the cubit', (tester) async {
    await pumpView(tester, loaded(days: days));

    await tester.tap(find.byKey(const Key('admin_stats_refresh')));
    verify(() => cubit.refresh()).called(1);
    await tester.tap(find.byKey(const Key('admin_stats_range_quarter')));
    verify(() => cubit.selectRange(AdminStatsRange.quarter)).called(1);
  });

  testWidgets('fits the smallest window the app allows', (tester) async {
    await pumpView(tester, loaded(days: days), size: const Size(780, 600));
    expect(tester.takeException(), isNull);
  });
}
