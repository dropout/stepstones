// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'Stepstones Admin';

  @override
  String get navChants => 'Énekek';

  @override
  String get navPresence => 'Jelenlét';

  @override
  String get navStats => 'Globális statisztika';

  @override
  String get signOut => 'Kijelentkezés';

  @override
  String get comingSoon => 'Ez a rész még nem készült el.';

  @override
  String get initErrorTitle => 'Az admin alkalmazás nem tudott elindulni';
}
