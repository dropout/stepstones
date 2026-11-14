import 'dart:async';

import 'package:clock/clock.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_stats/src/domain/entity/daily_global_stats_entity.dart';
import 'package:admin_stats/src/domain/entity/global_stats_entity.dart';
import 'package:admin_stats/src/domain/enum/admin_stats_range.dart';
import 'package:admin_stats/src/presentation/viewmodel/admin_stats_cubit.dart';

import '../../admin_stats_mock_definitions.dart';

void main() {
  late MockAdminStatsRepository repository;
  late MockCrashlyticsService crashlytics;
  late StreamController<GlobalStatsEntity> allTime;
  late List<List<DateTime>> requestedDays;
  // Sessions reported for each requested day; tests change it to simulate new data.
  late int sessionsPerDay;

  final now = DateTime.utc(2026, 11, 14, 22, 30);
  final today = DateTime.utc(2026, 11, 14);

  GlobalStatsEntity stats(int sessions) => GlobalStatsEntity(
    totalSessions: sessions,
    totalDuration: Duration(minutes: sessions * 10),
  );

  setUp(() {
    repository = MockAdminStatsRepository();
    crashlytics = MockCrashlyticsService();
    allTime = StreamController<GlobalStatsEntity>();
    requestedDays = [];
    sessionsPerDay = 1;
    when(() => repository.watchAllTime()).thenAnswer((_) => allTime.stream);
    when(() => repository.loadDays(any())).thenAnswer((invocation) async {
      final days = invocation.positionalArguments.single as List<DateTime>;
      requestedDays.add(days);
      return [for (final day in days) DailyGlobalStatsEntity(day: day, stats: stats(sessionsPerDay))];
    });
  });

  // Not awaited: closing a controller nobody listened to never completes.
  tearDown(() {
    allTime.close();
  });

  AdminStatsCubit buildCubit() => AdminStatsCubit(adminStatsRepository: repository, crashlyticsService: crashlytics);

  /// Lets queued stream events and awaited loads finish.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<AdminStatsCubit> startedCubit() async {
    final cubit = buildCubit();
    await cubit.start();
    allTime.add(stats(100));
    await settle();
    return cubit;
  }

  AdminStatsLoadedState loaded(AdminStatsCubit cubit) => cubit.state as AdminStatsLoadedState;

  void verifyErrorRecorded() => verify(
    () => crashlytics.recordError(
      exception: any(named: 'exception'),
      stackTrace: any(named: 'stackTrace'),
      reason: any(named: 'reason'),
    ),
  ).called(1);

  test('start shows the all-time totals and loads the last 30 UTC days', () async {
    await withClock(Clock.fixed(now), () async {
      final cubit = await startedCubit();

      expect(loaded(cubit).allTime, stats(100));
      expect(loaded(cubit).range, AdminStatsRange.month);
      expect(loaded(cubit).dailyStatus, AdminStatsDailyStatus.loaded);
      expect(requestedDays.single, hasLength(30));
      expect(requestedDays.single.first, DateTime.utc(2026, 10, 16));
      expect(requestedDays.single.last, today);
      expect(loaded(cubit).today, stats(1));
      expect(loaded(cubit).rangeTotal, stats(30));
      await cubit.close();
    });
  });

  test('uses the UTC day even when the local day differs', () async {
    // 01:30 on the 15th at UTC+3 is still the 14th in UTC.
    await withClock(Clock.fixed(DateTime.parse('2026-11-15T01:30:00+03:00')), () async {
      final cubit = await startedCubit();
      expect(requestedDays.single.last, today);
      await cubit.close();
    });
  });

  test('a changed all-time total re-fetches only today', () async {
    await withClock(Clock.fixed(now), () async {
      final cubit = await startedCubit();
      sessionsPerDay = 2;
      allTime.add(stats(101));
      await settle();

      expect(loaded(cubit).allTime, stats(101));
      expect(requestedDays.last, [today]);
      expect(loaded(cubit).days, hasLength(30));
      expect(loaded(cubit).today, stats(2));
      expect(loaded(cubit).days.first.stats, stats(1));
      await cubit.close();
    });
  });

  test('an unchanged all-time total does not re-fetch', () async {
    await withClock(Clock.fixed(now), () async {
      final cubit = await startedCubit();
      allTime.add(stats(100));
      await settle();

      expect(requestedDays, hasLength(1));
      await cubit.close();
    });
  });

  test('reloads the whole range when the UTC day has rolled over', () async {
    var current = now;
    await withClock(Clock(() => current), () async {
      final cubit = await startedCubit();
      current = now.add(const Duration(hours: 2));
      allTime.add(stats(101));
      await settle();
      await settle();

      expect(requestedDays.last, hasLength(30));
      expect(loaded(cubit).days.last.day, DateTime.utc(2026, 11, 15));
      await cubit.close();
    });
  });

  test('selectRange clears the days and loads the new range', () async {
    await withClock(Clock.fixed(now), () async {
      final cubit = await startedCubit();
      final states = <AdminStatsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.selectRange(AdminStatsRange.week);
      await settle();

      final first = states.first as AdminStatsLoadedState;
      expect(first.range, AdminStatsRange.week);
      expect(first.dailyStatus, AdminStatsDailyStatus.loading);
      expect(first.days, isEmpty);
      expect(requestedDays.last, hasLength(7));
      expect(loaded(cubit).rangeTotal, stats(7));

      await cubit.selectRange(AdminStatsRange.week);
      expect(requestedDays, hasLength(2));
      await sub.cancel();
      await cubit.close();
    });
  });

  test('refresh reloads the current range and keeps the old days meanwhile', () async {
    await withClock(Clock.fixed(now), () async {
      final cubit = await startedCubit();
      final states = <AdminStatsState>[];
      final sub = cubit.stream.listen(states.add);
      sessionsPerDay = 3;

      await cubit.refresh();
      await settle();

      final first = states.first as AdminStatsLoadedState;
      expect(first.dailyStatus, AdminStatsDailyStatus.loading);
      expect(first.days, hasLength(30));
      expect(loaded(cubit).dailyStatus, AdminStatsDailyStatus.loaded);
      expect(loaded(cubit).rangeTotal, stats(90));
      await sub.cancel();
      await cubit.close();
    });
  });

  test('a failed daily load is recorded and keeps the all-time totals', () async {
    await withClock(Clock.fixed(now), () async {
      when(() => repository.loadDays(any())).thenThrow(StateError('offline'));
      final cubit = await startedCubit();

      expect(loaded(cubit).allTime, stats(100));
      expect(loaded(cubit).dailyStatus, AdminStatsDailyStatus.failed);
      verifyErrorRecorded();
      await cubit.close();
    });
  });

  test('a stream error is recorded and shown, and start retries', () async {
    final cubit = buildCubit();
    await cubit.start();
    allTime.addError(StateError('denied'));
    await settle();

    expect(cubit.state, const AdminStatsState.error());
    verifyErrorRecorded();

    allTime = StreamController<GlobalStatsEntity>();
    await cubit.start();
    expect(cubit.state, const AdminStatsState.loading());
    await cubit.close();
  });

  test('restarting and closing leave no listener behind', () async {
    final controllers = <StreamController<GlobalStatsEntity>>[];
    when(() => repository.watchAllTime()).thenAnswer((_) {
      controllers.add(StreamController<GlobalStatsEntity>());
      return controllers.last.stream;
    });
    final cubit = buildCubit();

    await cubit.start();
    await cubit.start();
    await settle();
    expect([for (final controller in controllers) controller.hasListener], [false, true]);

    await cubit.close();
    expect([for (final controller in controllers) controller.hasListener], [false, false]);
  });
}
