// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_access_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AdminAccessLocalizationsHu extends AdminAccessLocalizations {
  AdminAccessLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get signInTitle => 'Stepstones Admin';

  @override
  String get signInSubtitle => 'Jelentkezz be egy admin fiókkal.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Jelszó';

  @override
  String get signInButton => 'Bejelentkezés';

  @override
  String get signInFailed => 'Sikertelen bejelentkezés. Ellenőrizd az e-mail címet és a jelszót.';

  @override
  String get unauthorizedTitle => 'Ez nem admin fiók';

  @override
  String unauthorizedBody(String email) {
    return 'A(z) $email fióknak nincs admin jogosultsága.';
  }

  @override
  String get recheckButton => 'Ellenőrzés újra';

  @override
  String get signOutButton => 'Kijelentkezés';

  @override
  String get errorTitle => 'Nem sikerült ellenőrizni az admin jogosultságot';

  @override
  String get retryButton => 'Újra';
}
