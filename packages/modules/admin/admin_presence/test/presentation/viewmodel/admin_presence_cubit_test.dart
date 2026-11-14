import 'dart:async';

import 'package:core/core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_presence/src/domain/entity/admin_presence_entity.dart';
import 'package:admin_presence/src/domain/entity/admin_presence_location_entity.dart';
import 'package:admin_presence/src/domain/enum/admin_presence_window.dart';
import 'package:admin_presence/src/presentation/viewmodel/admin_presence_cubit.dart';

import '../../admin_presence_mock_definitions.dart';

void main() {
  late MockAdminPresenceRepository repository;
  late MockCrashlyticsService crashlytics;
  late StreamController<List<AdminPresenceEntity>> controller;

  final start = DateTime(2026, 11, 14, 12);

  AdminPresenceEntity entry(String id, Duration age, {String? location}) =>
      AdminPresenceEntity(profileId: id, firstName: id, startedAt: start.subtract(age), locationName: location);

  setUp(() {
    repository = MockAdminPresenceRepository();
    crashlytics = MockCrashlyticsService();
    controller = StreamController<List<AdminPresenceEntity>>.broadcast();
    when(
      () => repository.watchPresence(
        since: any(named: 'since'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) => controller.stream);
  });

  tearDown(() => controller.close());

  /// Runs [body] with a fake clock starting at [start], collecting every emitted state.
  void run(void Function(FakeAsync async, AdminPresenceCubit cubit, List<AdminPresenceState> states) body) {
    fakeAsync((async) {
      final cubit = AdminPresenceCubit(adminPresenceRepository: repository, crashlyticsService: crashlytics);
      final states = <AdminPresenceState>[];
      cubit.stream.listen(states.add);
      body(async, cubit, states);
      cubit.close();
      async.flushMicrotasks();
    }, initialTime: start);
  }

  AdminPresenceLoadedState lastLoaded(List<AdminPresenceState> states) => states.last as AdminPresenceLoadedState;

  test('start listens from the start of the default window', () {
    run((async, cubit, states) {
      cubit.start();
      async.flushMicrotasks();

      expect(cubit.state, const AdminPresenceState.loading(window: AdminPresenceWindow.threeHours));
      verify(
        () =>
            repository.watchPresence(since: start.subtract(const Duration(hours: 3)), limit: AdminPresenceCubit.limit),
      ).called(1);
    });
  });

  test('emits entries and follows later changes', () {
    run((async, cubit, states) {
      final a = entry('a', const Duration(minutes: 5));
      final b = entry('b', const Duration(minutes: 20));
      cubit.start();
      async.flushMicrotasks();
      controller.add([a]);
      async.flushMicrotasks();
      controller.add([a, b]);
      async.flushMicrotasks();

      expect(lastLoaded(states).entries, [a, b]);
      expect(lastLoaded(states).now, start);
      expect(lastLoaded(states).truncated, isFalse);
    });
  });

  test('counts entries by location with unknown locations last', () {
    run((async, cubit, states) {
      cubit.start();
      async.flushMicrotasks();
      controller.add([
        entry('a', const Duration(minutes: 1)),
        entry('b', const Duration(minutes: 2)),
        entry('c', const Duration(minutes: 3)),
        entry('d', const Duration(minutes: 4), location: 'Szeged'),
        entry('e', const Duration(minutes: 5), location: 'Budapest'),
        entry('f', const Duration(minutes: 6), location: 'Budapest'),
      ]);
      async.flushMicrotasks();

      expect(lastLoaded(states).locations, const [
        AdminPresenceLocationEntity(name: 'Budapest', count: 2),
        AdminPresenceLocationEntity(name: 'Szeged', count: 1),
        AdminPresenceLocationEntity(name: null, count: 3),
      ]);
    });
  });

  test('drops entries that age out of the window without a new snapshot', () {
    run((async, cubit, states) {
      final fresh = entry('fresh', const Duration(minutes: 5));
      final ageing = entry('ageing', const Duration(hours: 2, minutes: 58));
      cubit.start();
      async.flushMicrotasks();
      controller.add([fresh, ageing]);
      async.flushMicrotasks();
      expect(lastLoaded(states).entries, [fresh, ageing]);

      async.elapse(const Duration(minutes: 3));

      expect(lastLoaded(states).entries, [fresh]);
      expect(lastLoaded(states).now, start.add(const Duration(minutes: 3)));
    });
  });

  test('flags a result that reached the limit', () {
    run((async, cubit, states) {
      cubit.start();
      async.flushMicrotasks();
      controller.add([for (var i = 0; i < AdminPresenceCubit.limit; i++) entry('p$i', Duration(seconds: i))]);
      async.flushMicrotasks();

      expect(lastLoaded(states).truncated, isTrue);
    });
  });

  test('selectWindow restarts the listener for the new window', () {
    run((async, cubit, states) {
      cubit.start();
      async.flushMicrotasks();
      controller.add([entry('a', const Duration(minutes: 5))]);
      async.flushMicrotasks();

      cubit.selectWindow(AdminPresenceWindow.week);
      async.flushMicrotasks();

      expect(cubit.state, const AdminPresenceState.loading(window: AdminPresenceWindow.week));
      verify(
        () => repository.watchPresence(since: start.subtract(const Duration(days: 7)), limit: AdminPresenceCubit.limit),
      ).called(1);

      final old = entry('old', const Duration(days: 2));
      controller.add([old]);
      async.flushMicrotasks();
      expect(lastLoaded(states).entries, [old]);
      expect(lastLoaded(states).window, AdminPresenceWindow.week);
    });
  });

  test('selectWindow ignores the window that is already selected', () {
    run((async, cubit, states) {
      cubit.start();
      async.flushMicrotasks();
      cubit.selectWindow(AdminPresenceWindow.threeHours);
      async.flushMicrotasks();

      verify(
        () => repository.watchPresence(
          since: any(named: 'since'),
          limit: any(named: 'limit'),
        ),
      ).called(1);
    });
  });

  test('a stream error is recorded and shown, and start retries', () {
    run((async, cubit, states) {
      cubit.start();
      async.flushMicrotasks();
      controller.addError(StateError('denied'));
      async.flushMicrotasks();

      expect(cubit.state, const AdminPresenceState.error(window: AdminPresenceWindow.threeHours));
      verify(
        () => crashlytics.recordError(
          exception: any(named: 'exception'),
          stackTrace: any(named: 'stackTrace'),
          reason: any(named: 'reason'),
        ),
      ).called(1);

      cubit.start();
      async.flushMicrotasks();
      expect(cubit.state, const AdminPresenceState.loading(window: AdminPresenceWindow.threeHours));
    });
  });

  test('selectWindow and close leave no listener behind', () {
    fakeAsync((async) {
      final controllers = <StreamController<List<AdminPresenceEntity>>>[];
      when(
        () => repository.watchPresence(
          since: any(named: 'since'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) {
        controllers.add(StreamController<List<AdminPresenceEntity>>());
        return controllers.last.stream;
      });
      final cubit = AdminPresenceCubit(adminPresenceRepository: repository, crashlyticsService: crashlytics);

      cubit.start();
      async.flushMicrotasks();
      cubit.selectWindow(AdminPresenceWindow.week);
      async.flushMicrotasks();
      expect([for (final controller in controllers) controller.hasListener], [false, true]);

      cubit.close();
      async.flushMicrotasks();
      expect([for (final controller in controllers) controller.hasListener], [false, false]);
      expect(async.periodicTimerCount, 0);
    }, initialTime: start);
  });
}
