import 'package:admin_presence/l10n/admin_presence_localizations.dart';
import 'package:admin_presence/src/domain/enum/admin_presence_window.dart';

String _two(int value) => value.toString().padLeft(2, '0');

/// Clock time of a start, prefixed with the date when it was not today.
String formatPresenceClock(DateTime startedAt, DateTime now) {
  final time = '${_two(startedAt.hour)}:${_two(startedAt.minute)}';
  final sameDay = startedAt.year == now.year && startedAt.month == now.month && startedAt.day == now.day;
  return sameDay ? time : '${startedAt.year}-${_two(startedAt.month)}-${_two(startedAt.day)} $time';
}

String formatPresenceAge(AdminPresenceLocalizations l10n, DateTime startedAt, DateTime now) {
  final elapsed = now.difference(startedAt);
  if (elapsed.inMinutes < 1) return l10n.startedJustNow;
  if (elapsed.inHours < 1) return l10n.startedMinutesAgo(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.startedHoursAgo(elapsed.inHours);
  return l10n.startedDaysAgo(elapsed.inDays);
}

String presenceWindowLabel(AdminPresenceLocalizations l10n, AdminPresenceWindow window) => switch (window) {
  .hour => l10n.windowHour,
  .threeHours => l10n.windowThreeHours,
  .day => l10n.windowDay,
  .week => l10n.windowWeek,
};
