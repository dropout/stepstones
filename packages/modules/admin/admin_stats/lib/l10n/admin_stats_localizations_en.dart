// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_stats_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AdminStatsLocalizationsEn extends AdminStatsLocalizations {
  AdminStatsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get statsTitle => 'Global stats';

  @override
  String get statsError => 'Unable to load global stats.';

  @override
  String get retryButton => 'Retry';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get allTimeTitle => 'All time';

  @override
  String get todayTitle => 'Today (UTC)';

  @override
  String rangeTitle(int days) {
    return 'Last $days days';
  }

  @override
  String sessionsCount(int count) {
    return '$count sessions';
  }

  @override
  String practiceTime(String time) {
    return '$time practiced';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String typeBreakdown(String type, int count) {
    return '$type: $count';
  }

  @override
  String get typeTimer => 'Timer';

  @override
  String get typeChanting => 'Chanting';

  @override
  String get rangeWeek => '7 days';

  @override
  String get rangeMonth => '30 days';

  @override
  String get rangeQuarter => '90 days';

  @override
  String get dailyTitle => 'Sessions per day';

  @override
  String get dailyLoading => 'Loading daily history…';

  @override
  String get dailyFailed => 'The daily history could not be loaded.';

  @override
  String get dayColumn => 'Day (UTC)';

  @override
  String get sessionsColumn => 'Sessions';

  @override
  String get timeColumn => 'Time';

  @override
  String dayTooltip(String day, int count) {
    return '$day: $count sessions';
  }

  @override
  String get noSessionsYet =>
      'No sessions have been counted yet. Totals grow as sessions are recorded while the aggregation function is deployed.';
}
