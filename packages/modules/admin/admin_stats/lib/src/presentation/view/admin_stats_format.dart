import 'package:admin_stats/l10n/admin_stats_localizations.dart';
import 'package:admin_stats/src/domain/enum/admin_stats_range.dart';

String _two(int value) => value.toString().padLeft(2, '0');

String formatStatsDay(DateTime day) => '${day.year}-${_two(day.month)}-${_two(day.day)}';

String formatStatsDuration(AdminStatsLocalizations l10n, Duration duration) {
  final minutes = duration.inMinutes.remainder(60);
  return duration.inHours > 0 ? l10n.durationHoursMinutes(duration.inHours, minutes) : l10n.durationMinutes(minutes);
}

/// Known session types get a translated label; an unexpected one is shown as stored.
String statsSessionTypeLabel(AdminStatsLocalizations l10n, String type) => switch (type) {
  'timer' => l10n.typeTimer,
  'chanting' => l10n.typeChanting,
  _ => type,
};

String statsRangeLabel(AdminStatsLocalizations l10n, AdminStatsRange range) => switch (range) {
  .week => l10n.rangeWeek,
  .month => l10n.rangeMonth,
  .quarter => l10n.rangeQuarter,
};
