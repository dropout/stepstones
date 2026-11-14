// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_stats_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AdminStatsLocalizationsHu extends AdminStatsLocalizations {
  AdminStatsLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get statsTitle => 'Globális statisztika';

  @override
  String get statsError => 'A globális statisztika betöltése nem sikerült.';

  @override
  String get retryButton => 'Újra';

  @override
  String get refreshButton => 'Frissítés';

  @override
  String get allTimeTitle => 'Összesen';

  @override
  String get todayTitle => 'Ma (UTC)';

  @override
  String rangeTitle(int days) {
    return 'Elmúlt $days nap';
  }

  @override
  String sessionsCount(int count) {
    return '$count alkalom';
  }

  @override
  String practiceTime(String time) {
    return '$time gyakorlás';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ó $minutes p';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes p';
  }

  @override
  String typeBreakdown(String type, int count) {
    return '$type: $count';
  }

  @override
  String get typeTimer => 'Időzítő';

  @override
  String get typeChanting => 'Éneklés';

  @override
  String get rangeWeek => '7 nap';

  @override
  String get rangeMonth => '30 nap';

  @override
  String get rangeQuarter => '90 nap';

  @override
  String get dailyTitle => 'Alkalmak naponta';

  @override
  String get dailyLoading => 'Napi előzmények betöltése…';

  @override
  String get dailyFailed => 'A napi előzmények betöltése nem sikerült.';

  @override
  String get dayColumn => 'Nap (UTC)';

  @override
  String get sessionsColumn => 'Alkalmak';

  @override
  String get timeColumn => 'Idő';

  @override
  String dayTooltip(String day, int count) {
    return '$day: $count alkalom';
  }

  @override
  String get noSessionsYet =>
      'Még nincs megszámolt alkalom. Az összesítés akkor nő, amikor az összesítő függvény telepítve van és új alkalmak rögzülnek.';
}
