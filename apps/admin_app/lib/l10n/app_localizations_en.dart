// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stepstones Admin';

  @override
  String get navChants => 'Chants';

  @override
  String get navPresence => 'Presence';

  @override
  String get navStats => 'Global stats';

  @override
  String get signOut => 'Sign out';

  @override
  String get initErrorTitle => 'The admin app could not start';
}
