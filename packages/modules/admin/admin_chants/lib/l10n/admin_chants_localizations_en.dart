// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_chants_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AdminChantsLocalizationsEn extends AdminChantsLocalizations {
  AdminChantsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get chantsTitle => 'Chants';

  @override
  String chantsCount(int count) {
    return '$count in the catalog';
  }

  @override
  String get chantsEmpty => 'No chants in the catalog yet.';

  @override
  String get chantsError => 'Unable to load chants.';

  @override
  String get retryButton => 'Retry';

  @override
  String get saveFailed => 'The change could not be saved.';

  @override
  String get selectChantHint => 'Select a chant to see its details.';

  @override
  String get nameLabel => 'Name';

  @override
  String get saveButton => 'Save';

  @override
  String get detailId => 'ID';

  @override
  String get detailLength => 'Length';

  @override
  String get detailPlayCount => 'Plays';

  @override
  String get detailUpdated => 'Assets updated';

  @override
  String get detailAudio => 'Audio';

  @override
  String get detailLyrics => 'Lyrics';

  @override
  String get detailCover => 'Cover';

  @override
  String assetSummary(int version, String size) {
    return 'v$version · $size';
  }

  @override
  String get missingBlurHash =>
      'No blurHash: the mobile app cannot load this chant.';

  @override
  String chantSubtitle(String length, int plays) {
    return '$length · $plays plays';
  }

  @override
  String get newChantButton => 'New chant';

  @override
  String get uploadTitle => 'New chant';

  @override
  String get idLabel => 'ID';

  @override
  String get idHelper =>
      'Lowercase letters, numbers and dashes. Cannot be changed later.';

  @override
  String get chooseFileButton => 'Choose…';

  @override
  String get noFileChosen => 'No file chosen';

  @override
  String get uploadButton => 'Upload';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get replaceButton => 'Replace…';

  @override
  String get uploadFailed =>
      'The upload failed. Nothing was added to the catalog.';

  @override
  String get failureEmptyName => 'Enter a name.';

  @override
  String get failureNameTooLong => 'The name is too long.';

  @override
  String get failureInvalidId =>
      'The ID may only contain lowercase letters, numbers and single dashes.';

  @override
  String get failureDuplicateId => 'A chant with this ID already exists.';

  @override
  String get failureMissingFile => 'Choose the audio, lyrics and cover files.';

  @override
  String get failureEmptyFile => 'One of the files is empty.';

  @override
  String get failureUnreadableAsset =>
      'A file could not be read. Check that the audio is a valid MP3 and the cover a valid JPEG.';
}
