import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'admin_presence_localizations_en.dart';
import 'admin_presence_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AdminPresenceLocalizations
/// returned by `AdminPresenceLocalizations.of(context)`.
///
/// Applications need to include `AdminPresenceLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/admin_presence_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AdminPresenceLocalizations.localizationsDelegates,
///   supportedLocales: AdminPresenceLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AdminPresenceLocalizations.supportedLocales
/// property.
abstract class AdminPresenceLocalizations {
  AdminPresenceLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AdminPresenceLocalizations of(BuildContext context) {
    return Localizations.of<AdminPresenceLocalizations>(
      context,
      AdminPresenceLocalizations,
    )!;
  }

  static const LocalizationsDelegate<AdminPresenceLocalizations> delegate =
      _AdminPresenceLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hu'),
  ];

  /// No description provided for @presenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Presence'**
  String get presenceTitle;

  /// No description provided for @presenceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} started practicing in the past {window}'**
  String presenceCount(int count, String window);

  /// No description provided for @presenceLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get presenceLive;

  /// No description provided for @presenceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody started practicing in this period.'**
  String get presenceEmpty;

  /// No description provided for @presenceError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load presence.'**
  String get presenceError;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @presenceTruncated.
  ///
  /// In en, this message translates to:
  /// **'Only the latest {limit} are shown.'**
  String presenceTruncated(int limit);

  /// No description provided for @windowHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get windowHour;

  /// No description provided for @windowThreeHours.
  ///
  /// In en, this message translates to:
  /// **'3 hours'**
  String get windowThreeHours;

  /// No description provided for @windowDay.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get windowDay;

  /// No description provided for @windowWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get windowWeek;

  /// No description provided for @startedJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get startedJustNow;

  /// No description provided for @startedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String startedMinutesAgo(int minutes);

  /// No description provided for @startedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String startedHoursAgo(int hours);

  /// No description provided for @startedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} d ago'**
  String startedDaysAgo(int days);

  /// No description provided for @byLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'By location'**
  String get byLocationTitle;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'No location shared'**
  String get unknownLocation;
}

class _AdminPresenceLocalizationsDelegate
    extends LocalizationsDelegate<AdminPresenceLocalizations> {
  const _AdminPresenceLocalizationsDelegate();

  @override
  Future<AdminPresenceLocalizations> load(Locale locale) {
    return SynchronousFuture<AdminPresenceLocalizations>(
      lookupAdminPresenceLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AdminPresenceLocalizationsDelegate old) => false;
}

AdminPresenceLocalizations lookupAdminPresenceLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AdminPresenceLocalizationsEn();
    case 'hu':
      return AdminPresenceLocalizationsHu();
  }

  throw FlutterError(
    'AdminPresenceLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
