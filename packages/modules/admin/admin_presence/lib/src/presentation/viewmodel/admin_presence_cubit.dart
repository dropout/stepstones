import 'dart:async';

import 'package:clock/clock.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin_presence/src/domain/entity/admin_presence_entity.dart';
import 'package:admin_presence/src/domain/entity/admin_presence_location_entity.dart';
import 'package:admin_presence/src/domain/enum/admin_presence_window.dart';
import 'package:admin_presence/src/domain/repository/admin_presence_repository.dart';

part 'admin_presence_cubit.freezed.dart';

@freezed
sealed class AdminPresenceState with _$AdminPresenceState {
  const AdminPresenceState._();
  const factory AdminPresenceState.loading({required AdminPresenceWindow window}) = AdminPresenceLoadingState;
  const factory AdminPresenceState.loaded({
    required AdminPresenceWindow window,
    required List<AdminPresenceEntity> entries,
    required List<AdminPresenceLocationEntity> locations,
    required DateTime now,
    @Default(false) bool truncated,
  }) = AdminPresenceLoadedState;
  const factory AdminPresenceState.error({required AdminPresenceWindow window}) = AdminPresenceErrorState;
}

class AdminPresenceCubit extends Cubit<AdminPresenceState> {
  static const limit = 200;

  final AdminPresenceRepository adminPresenceRepository;
  final CrashlyticsService crashlyticsService;
  final Duration refreshInterval;

  StreamSubscription<List<AdminPresenceEntity>>? _presenceSub;
  Timer? _refreshTimer;
  List<AdminPresenceEntity> _latest = const [];

  AdminPresenceCubit({
    required this.adminPresenceRepository,
    required this.crashlyticsService,
    this.refreshInterval = const Duration(minutes: 1),
  }) : super(const AdminPresenceState.loading(window: .threeHours));

  /// Starts listening for the given [window], or restarts the current one.
  Future<void> start([AdminPresenceWindow? window]) async {
    final selected = window ?? state.window;
    // Not awaited: a cancelled subscription delivers nothing further, so the new one can start right away.
    unawaited(_stopListening());
    if (isClosed) return;
    emit(AdminPresenceState.loading(window: selected));
    _presenceSub = adminPresenceRepository
        .watchPresence(since: clock.now().subtract(selected.duration), limit: limit)
        .listen(
          (entries) {
            _latest = entries;
            _emitLoaded(selected);
          },
          onError: (Object error, StackTrace stackTrace) {
            crashlyticsService.recordError(exception: error, stackTrace: stackTrace, reason: 'Unable to load presence');
            if (!isClosed) emit(AdminPresenceState.error(window: selected));
          },
        );
    // The query's lower bound is fixed at subscription time, so ageing entries are dropped here instead.
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      if (state is AdminPresenceLoadedState) _emitLoaded(selected);
    });
  }

  Future<void> selectWindow(AdminPresenceWindow window) async {
    if (window == state.window) return;
    await start(window);
  }

  void _emitLoaded(AdminPresenceWindow window) {
    if (isClosed) return;
    final now = clock.now();
    final threshold = now.subtract(window.duration);
    final entries = [
      for (final entry in _latest)
        if (!entry.startedAt.isBefore(threshold)) entry,
    ];
    emit(
      AdminPresenceState.loaded(
        window: window,
        entries: entries,
        locations: _countByLocation(entries),
        now: now,
        truncated: _latest.length >= limit,
      ),
    );
  }

  List<AdminPresenceLocationEntity> _countByLocation(List<AdminPresenceEntity> entries) {
    final counts = <String?, int>{};
    for (final entry in entries) {
      counts.update(entry.locationName, (count) => count + 1, ifAbsent: () => 1);
    }
    final locations = [
      for (final MapEntry(:key, :value) in counts.entries) AdminPresenceLocationEntity(name: key, count: value),
    ];
    // Largest first, with the group that shares no location always last.
    locations.sort((a, b) {
      if ((a.name == null) != (b.name == null)) return a.name == null ? 1 : -1;
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : (a.name ?? '').compareTo(b.name ?? '');
    });
    return locations;
  }

  Future<void> _stopListening() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    // Detached before the await so a listener started meanwhile is not the one forgotten.
    final subscription = _presenceSub;
    _presenceSub = null;
    await subscription?.cancel();
  }

  @override
  Future<void> close() async {
    await _stopListening();
    return super.close();
  }
}
