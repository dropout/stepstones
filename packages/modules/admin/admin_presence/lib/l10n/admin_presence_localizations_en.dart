// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_presence_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AdminPresenceLocalizationsEn extends AdminPresenceLocalizations {
  AdminPresenceLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get presenceTitle => 'Presence';

  @override
  String presenceCount(int count, String window) {
    return '$count started practicing in the past $window';
  }

  @override
  String get presenceLive => 'Live';

  @override
  String get presenceEmpty => 'Nobody started practicing in this period.';

  @override
  String get presenceError => 'Unable to load presence.';

  @override
  String get retryButton => 'Retry';

  @override
  String presenceTruncated(int limit) {
    return 'Only the latest $limit are shown.';
  }

  @override
  String get windowHour => '1 hour';

  @override
  String get windowThreeHours => '3 hours';

  @override
  String get windowDay => '24 hours';

  @override
  String get windowWeek => '7 days';

  @override
  String get startedJustNow => 'just now';

  @override
  String startedMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String startedHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String startedDaysAgo(int days) {
    return '$days d ago';
  }

  @override
  String get byLocationTitle => 'By location';

  @override
  String get unknownLocation => 'No location shared';
}
