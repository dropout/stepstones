// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'admin_chants_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AdminChantsLocalizationsHu extends AdminChantsLocalizations {
  AdminChantsLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get chantsTitle => 'Énekek';

  @override
  String chantsCount(int count) {
    return '$count a katalógusban';
  }

  @override
  String get chantsEmpty => 'Még nincs ének a katalógusban.';

  @override
  String get chantsError => 'Nem sikerült betölteni az énekeket.';

  @override
  String get retryButton => 'Újra';

  @override
  String get saveFailed => 'A módosítást nem sikerült menteni.';

  @override
  String get selectChantHint => 'Válassz egy éneket a részletekhez.';

  @override
  String get nameLabel => 'Név';

  @override
  String get saveButton => 'Mentés';

  @override
  String get detailId => 'Azonosító';

  @override
  String get detailLength => 'Hossz';

  @override
  String get detailPlayCount => 'Lejátszások';

  @override
  String get detailUpdated => 'Fájlok frissítve';

  @override
  String get detailAudio => 'Hang';

  @override
  String get detailLyrics => 'Szöveg';

  @override
  String get detailCover => 'Borító';

  @override
  String assetSummary(int version, String size) {
    return 'v$version · $size';
  }

  @override
  String get notLoadableByMobileApp =>
      'A mobilalkalmazás nem tudja betölteni ezt az éneket: kötelező mezők hiányoznak.';

  @override
  String chantSubtitle(String length, int plays) {
    return '$length · $plays lejátszás';
  }

  @override
  String get newChantButton => 'Új ének';

  @override
  String get uploadTitle => 'Új ének';

  @override
  String get idLabel => 'Azonosító';

  @override
  String get idHelper =>
      'Kisbetűk, számok és kötőjelek. Később nem módosítható.';

  @override
  String get chooseFileButton => 'Tallózás…';

  @override
  String get noFileChosen => 'Nincs fájl kiválasztva';

  @override
  String get uploadButton => 'Feltöltés';

  @override
  String get cancelButton => 'Mégse';

  @override
  String get replaceButton => 'Csere…';

  @override
  String get uploadFailed =>
      'A feltöltés nem sikerült. Semmi nem került a katalógusba.';

  @override
  String get failureEmptyName => 'Adj meg egy nevet.';

  @override
  String get failureNameTooLong => 'A név túl hosszú.';

  @override
  String get failureInvalidId =>
      'Az azonosító csak kisbetűket, számokat és egyszeres kötőjeleket tartalmazhat.';

  @override
  String get failureDuplicateId => 'Már létezik ének ezzel az azonosítóval.';

  @override
  String get failureMissingFile =>
      'Válaszd ki a hang-, a szöveg- és a borítófájlt.';

  @override
  String get failureEmptyFile => 'Az egyik fájl üres.';

  @override
  String get failureUnreadableAsset =>
      'Egy fájlt nem sikerült beolvasni. Ellenőrizd, hogy a hang érvényes MP3, a borító pedig érvényes JPEG.';
}
