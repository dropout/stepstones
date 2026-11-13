// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_access_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AdminAccessLocalizationsEn extends AdminAccessLocalizations {
  AdminAccessLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get signInTitle => 'Stepstones Admin';

  @override
  String get signInSubtitle => 'Sign in with an admin account.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signInFailed => 'Sign-in failed. Check the email and password.';

  @override
  String get unauthorizedTitle => 'Not an admin account';

  @override
  String unauthorizedBody(String email) {
    return '$email does not have admin access.';
  }

  @override
  String get recheckButton => 'Check again';

  @override
  String get signOutButton => 'Sign out';

  @override
  String get errorTitle => 'Unable to verify admin access';

  @override
  String get retryButton => 'Retry';
}
