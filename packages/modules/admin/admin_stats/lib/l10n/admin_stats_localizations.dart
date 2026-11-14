import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'admin_stats_localizations_en.dart';
import 'admin_stats_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AdminStatsLocalizations
/// returned by `AdminStatsLocalizations.of(context)`.
///
/// Applications need to include `AdminStatsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/admin_stats_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AdminStatsLocalizations.localizationsDelegates,
///   supportedLocales: AdminStatsLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AdminStatsLocalizations.supportedLocales
/// property.
abstract class AdminStatsLocalizations {
  AdminStatsLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AdminStatsLocalizations of(BuildContext context) {
    return Localizations.of<AdminStatsLocalizations>(
      context,
      AdminStatsLocalizations,
    )!;
  }

  static const LocalizationsDelegate<AdminStatsLocalizations> delegate =
      _AdminStatsLocalizationsDelegate();

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

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Global stats'**
  String get statsTitle;

  /// No description provided for @statsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load global stats.'**
  String get statsError;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @refreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// No description provided for @allTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTimeTitle;

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today (UTC)'**
  String get todayTitle;

  /// No description provided for @rangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String rangeTitle(int days);

  /// No description provided for @sessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String sessionsCount(int count);

  /// No description provided for @practiceTime.
  ///
  /// In en, this message translates to:
  /// **'{time} practiced'**
  String practiceTime(String time);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @typeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{type}: {count}'**
  String typeBreakdown(String type, int count);

  /// No description provided for @typeTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get typeTimer;

  /// No description provided for @typeChanting.
  ///
  /// In en, this message translates to:
  /// **'Chanting'**
  String get typeChanting;

  /// No description provided for @rangeWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get rangeMonth;

  /// No description provided for @rangeQuarter.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get rangeQuarter;

  /// No description provided for @dailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions per day'**
  String get dailyTitle;

  /// No description provided for @dailyLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading daily history…'**
  String get dailyLoading;

  /// No description provided for @dailyFailed.
  ///
  /// In en, this message translates to:
  /// **'The daily history could not be loaded.'**
  String get dailyFailed;

  /// No description provided for @dayColumn.
  ///
  /// In en, this message translates to:
  /// **'Day (UTC)'**
  String get dayColumn;

  /// No description provided for @sessionsColumn.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsColumn;

  /// No description provided for @timeColumn.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeColumn;

  /// No description provided for @dayTooltip.
  ///
  /// In en, this message translates to:
  /// **'{day}: {count} sessions'**
  String dayTooltip(String day, int count);

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions have been counted yet. Totals grow as sessions are recorded while the aggregation function is deployed.'**
  String get noSessionsYet;
}

class _AdminStatsLocalizationsDelegate
    extends LocalizationsDelegate<AdminStatsLocalizations> {
  const _AdminStatsLocalizationsDelegate();

  @override
  Future<AdminStatsLocalizations> load(Locale locale) {
    return SynchronousFuture<AdminStatsLocalizations>(
      lookupAdminStatsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AdminStatsLocalizationsDelegate old) => false;
}

AdminStatsLocalizations lookupAdminStatsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AdminStatsLocalizationsEn();
    case 'hu':
      return AdminStatsLocalizationsHu();
  }

  throw FlutterError(
    'AdminStatsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
