import 'dart:async';

import 'package:clock/clock.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin_stats/src/domain/entity/daily_global_stats_entity.dart';
import 'package:admin_stats/src/domain/entity/global_stats_entity.dart';
import 'package:admin_stats/src/domain/enum/admin_stats_range.dart';
import 'package:admin_stats/src/domain/repository/admin_stats_repository.dart';

part 'admin_stats_cubit.freezed.dart';

enum AdminStatsDailyStatus { loading, loaded, failed }

@freezed
sealed class AdminStatsState with _$AdminStatsState {
  const AdminStatsState._();
  const factory AdminStatsState.loading() = AdminStatsLoadingState;
  const factory AdminStatsState.loaded({
    required GlobalStatsEntity allTime,
    required AdminStatsRange range,
    @Default(AdminStatsDailyStatus.loading) AdminStatsDailyStatus dailyStatus,
    // Oldest day first; empty until the first load of the range finishes.
    @Default([]) List<DailyGlobalStatsEntity> days,
  }) = AdminStatsLoadedState;
  const factory AdminStatsState.error() = AdminStatsErrorState;
}

extension AdminStatsLoadedTotals on AdminStatsLoadedState {
  GlobalStatsEntity get rangeTotal => GlobalStatsEntity.sum([for (final day in days) day.stats]);

  GlobalStatsEntity get today => days.isEmpty ? const GlobalStatsEntity() : days.last.stats;
}

class AdminStatsCubit extends Cubit<AdminStatsState> {
  final AdminStatsRepository adminStatsRepository;
  final CrashlyticsService crashlyticsService;

  StreamSubscription<GlobalStatsEntity>? _allTimeSub;
  // Bumped on every reload so a slower, older load cannot overwrite a newer one.
  int _dailyLoadId = 0;

  AdminStatsCubit({required this.adminStatsRepository, required this.crashlyticsService})
    : super(const AdminStatsState.loading());

  Future<void> start() async {
    final previous = _allTimeSub;
    _allTimeSub = null;
    unawaited(previous?.cancel());
    if (isClosed) return;
    emit(const AdminStatsState.loading());
    _allTimeSub = adminStatsRepository.watchAllTime().listen(
      _handleAllTime,
      onError: (Object error, StackTrace stackTrace) {
        crashlyticsService.recordError(exception: error, stackTrace: stackTrace, reason: 'Unable to load global stats');
        if (!isClosed) emit(const AdminStatsState.error());
      },
    );
  }

  Future<void> selectRange(AdminStatsRange range) async {
    final current = state;
    if (current is! AdminStatsLoadedState || current.range == range) return;
    emit(current.copyWith(range: range, dailyStatus: .loading, days: const []));
    await _loadDays(range);
  }

  /// Re-fetches the daily history of the selected range.
  Future<void> refresh() async {
    final current = state;
    if (current is! AdminStatsLoadedState || current.dailyStatus == .loading) return;
    emit(current.copyWith(dailyStatus: .loading));
    await _loadDays(current.range);
  }

  void _handleAllTime(GlobalStatsEntity allTime) {
    if (isClosed) return;
    final current = state;
    if (current is! AdminStatsLoadedState) {
      emit(AdminStatsState.loaded(allTime: allTime, range: .month));
      unawaited(_loadDays(.month));
      return;
    }
    emit(current.copyWith(allTime: allTime));
    // A changed total means a session was just counted, which can only have touched recent days.
    if (current.dailyStatus == .loaded && allTime != current.allTime) unawaited(_refreshToday());
  }

  List<DateTime> _daysEndingToday(int count) {
    final now = clock.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    return [for (var offset = count - 1; offset >= 0; offset--) today.subtract(Duration(days: offset))];
  }

  Future<void> _loadDays(AdminStatsRange range) async {
    final loadId = ++_dailyLoadId;
    try {
      final days = await adminStatsRepository.loadDays(_daysEndingToday(range.days));
      final current = state;
      if (isClosed || loadId != _dailyLoadId || current is! AdminStatsLoadedState) return;
      emit(current.copyWith(dailyStatus: .loaded, days: days));
    } catch (e, stack) {
      crashlyticsService.recordError(exception: e, stackTrace: stack, reason: 'Unable to load daily global stats');
      final current = state;
      if (isClosed || loadId != _dailyLoadId || current is! AdminStatsLoadedState) return;
      emit(current.copyWith(dailyStatus: .failed));
    }
  }

  Future<void> _refreshToday() async {
    final loadId = _dailyLoadId;
    final today = _daysEndingToday(1).single;
    try {
      final loaded = await adminStatsRepository.loadDays([today]);
      final current = state;
      if (isClosed || loadId != _dailyLoadId || current is! AdminStatsLoadedState) return;
      // After midnight UTC the list ends on yesterday, so the whole range is reloaded instead.
      if (current.days.isEmpty || current.days.last.day != today) {
        unawaited(_loadDays(current.range));
        return;
      }
      emit(current.copyWith(days: [...current.days.take(current.days.length - 1), loaded.single]));
    } catch (e, stack) {
      // Stale daily numbers are acceptable here; the next change or a manual refresh corrects them.
      crashlyticsService.recordError(
        exception: e,
        stackTrace: stack,
        reason: 'Unable to refresh today\'s global stats',
      );
    }
  }

  @override
  Future<void> close() async {
    final subscription = _allTimeSub;
    _allTimeSub = null;
    await subscription?.cancel();
    return super.close();
  }
}
