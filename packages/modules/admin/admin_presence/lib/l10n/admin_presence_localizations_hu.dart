// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_presence_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AdminPresenceLocalizationsHu extends AdminPresenceLocalizations {
  AdminPresenceLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get presenceTitle => 'Jelenlét';

  @override
  String presenceCount(int count, String window) {
    return 'Az elmúlt $window alatt $count fő kezdett gyakorolni';
  }

  @override
  String get presenceLive => 'Élő';

  @override
  String get presenceEmpty =>
      'Ebben az időszakban senki sem kezdett gyakorolni.';

  @override
  String get presenceError => 'A jelenlét betöltése nem sikerült.';

  @override
  String get retryButton => 'Újra';

  @override
  String presenceTruncated(int limit) {
    return 'Csak a legutóbbi $limit látható.';
  }

  @override
  String get windowHour => '1 óra';

  @override
  String get windowThreeHours => '3 óra';

  @override
  String get windowDay => '24 óra';

  @override
  String get windowWeek => '7 nap';

  @override
  String get startedJustNow => 'épp most';

  @override
  String startedMinutesAgo(int minutes) {
    return '$minutes perce';
  }

  @override
  String startedHoursAgo(int hours) {
    return '$hours órája';
  }

  @override
  String startedDaysAgo(int days) {
    return '$days napja';
  }

  @override
  String get byLocationTitle => 'Helyszín szerint';

  @override
  String get unknownLocation => 'Nincs megosztott helyszín';
}
