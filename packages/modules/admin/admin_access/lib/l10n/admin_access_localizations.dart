import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'admin_access_localizations_en.dart';
import 'admin_access_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AdminAccessLocalizations
/// returned by `AdminAccessLocalizations.of(context)`.
///
/// Applications need to include `AdminAccessLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/admin_access_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AdminAccessLocalizations.localizationsDelegates,
///   supportedLocales: AdminAccessLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AdminAccessLocalizations.supportedLocales
/// property.
abstract class AdminAccessLocalizations {
  AdminAccessLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AdminAccessLocalizations of(BuildContext context) {
    return Localizations.of<AdminAccessLocalizations>(context, AdminAccessLocalizations)!;
  }

  static const LocalizationsDelegate<AdminAccessLocalizations> delegate = _AdminAccessLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('hu')];

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Stepstones Admin'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with an admin account.'**
  String get signInSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Check the email and password.'**
  String get signInFailed;

  /// No description provided for @unauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not an admin account'**
  String get unauthorizedTitle;

  /// No description provided for @unauthorizedBody.
  ///
  /// In en, this message translates to:
  /// **'{email} does not have admin access.'**
  String unauthorizedBody(String email);

  /// No description provided for @recheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get recheckButton;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify admin access'**
  String get errorTitle;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;
}

class _AdminAccessLocalizationsDelegate extends LocalizationsDelegate<AdminAccessLocalizations> {
  const _AdminAccessLocalizationsDelegate();

  @override
  Future<AdminAccessLocalizations> load(Locale locale) {
    return SynchronousFuture<AdminAccessLocalizations>(lookupAdminAccessLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AdminAccessLocalizationsDelegate old) => false;
}

AdminAccessLocalizations lookupAdminAccessLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AdminAccessLocalizationsEn();
    case 'hu':
      return AdminAccessLocalizationsHu();
  }

  throw FlutterError(
    'AdminAccessLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
