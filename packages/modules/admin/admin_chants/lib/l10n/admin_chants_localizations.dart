import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'admin_chants_localizations_en.dart';
import 'admin_chants_localizations_hu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AdminChantsLocalizations
/// returned by `AdminChantsLocalizations.of(context)`.
///
/// Applications need to include `AdminChantsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/admin_chants_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AdminChantsLocalizations.localizationsDelegates,
///   supportedLocales: AdminChantsLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AdminChantsLocalizations.supportedLocales
/// property.
abstract class AdminChantsLocalizations {
  AdminChantsLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AdminChantsLocalizations of(BuildContext context) {
    return Localizations.of<AdminChantsLocalizations>(
      context,
      AdminChantsLocalizations,
    )!;
  }

  static const LocalizationsDelegate<AdminChantsLocalizations> delegate =
      _AdminChantsLocalizationsDelegate();

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

  /// No description provided for @chantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chants'**
  String get chantsTitle;

  /// No description provided for @chantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in the catalog'**
  String chantsCount(int count);

  /// No description provided for @chantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chants in the catalog yet.'**
  String get chantsEmpty;

  /// No description provided for @chantsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load chants.'**
  String get chantsError;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'The change could not be saved.'**
  String get saveFailed;

  /// No description provided for @selectChantHint.
  ///
  /// In en, this message translates to:
  /// **'Select a chant to see its details.'**
  String get selectChantHint;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @detailId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get detailId;

  /// No description provided for @detailLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get detailLength;

  /// No description provided for @detailPlayCount.
  ///
  /// In en, this message translates to:
  /// **'Plays'**
  String get detailPlayCount;

  /// No description provided for @detailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Assets updated'**
  String get detailUpdated;

  /// No description provided for @detailAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get detailAudio;

  /// No description provided for @detailLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get detailLyrics;

  /// No description provided for @detailCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get detailCover;

  /// No description provided for @assetSummary.
  ///
  /// In en, this message translates to:
  /// **'v{version} · {size}'**
  String assetSummary(int version, String size);

  /// No description provided for @missingBlurHash.
  ///
  /// In en, this message translates to:
  /// **'No blurHash: the mobile app cannot load this chant.'**
  String get missingBlurHash;

  /// No description provided for @chantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{length} · {plays} plays'**
  String chantSubtitle(String length, int plays);

  /// No description provided for @newChantButton.
  ///
  /// In en, this message translates to:
  /// **'New chant'**
  String get newChantButton;

  /// No description provided for @uploadTitle.
  ///
  /// In en, this message translates to:
  /// **'New chant'**
  String get uploadTitle;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @idHelper.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters, numbers and dashes. Cannot be changed later.'**
  String get idHelper;

  /// No description provided for @chooseFileButton.
  ///
  /// In en, this message translates to:
  /// **'Choose…'**
  String get chooseFileButton;

  /// No description provided for @noFileChosen.
  ///
  /// In en, this message translates to:
  /// **'No file chosen'**
  String get noFileChosen;

  /// No description provided for @uploadButton.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @replaceButton.
  ///
  /// In en, this message translates to:
  /// **'Replace…'**
  String get replaceButton;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The upload failed. Nothing was added to the catalog.'**
  String get uploadFailed;

  /// No description provided for @failureEmptyName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get failureEmptyName;

  /// No description provided for @failureNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'The name is too long.'**
  String get failureNameTooLong;

  /// No description provided for @failureInvalidId.
  ///
  /// In en, this message translates to:
  /// **'The ID may only contain lowercase letters, numbers and single dashes.'**
  String get failureInvalidId;

  /// No description provided for @failureDuplicateId.
  ///
  /// In en, this message translates to:
  /// **'A chant with this ID already exists.'**
  String get failureDuplicateId;

  /// No description provided for @failureMissingFile.
  ///
  /// In en, this message translates to:
  /// **'Choose the audio, lyrics and cover files.'**
  String get failureMissingFile;

  /// No description provided for @failureEmptyFile.
  ///
  /// In en, this message translates to:
  /// **'One of the files is empty.'**
  String get failureEmptyFile;

  /// No description provided for @failureUnreadableAsset.
  ///
  /// In en, this message translates to:
  /// **'A file could not be read. Check that the audio is a valid MP3 and the cover a valid JPEG.'**
  String get failureUnreadableAsset;
}

class _AdminChantsLocalizationsDelegate
    extends LocalizationsDelegate<AdminChantsLocalizations> {
  const _AdminChantsLocalizationsDelegate();

  @override
  Future<AdminChantsLocalizations> load(Locale locale) {
    return SynchronousFuture<AdminChantsLocalizations>(
      lookupAdminChantsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hu'].contains(locale.languageCode);

  @override
  bool shouldReload(_AdminChantsLocalizationsDelegate old) => false;
}

AdminChantsLocalizations lookupAdminChantsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AdminChantsLocalizationsEn();
    case 'hu':
      return AdminChantsLocalizationsHu();
  }

  throw FlutterError(
    'AdminChantsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
