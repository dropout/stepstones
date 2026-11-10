// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'chanting_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class ChantingLocalizationsHu extends ChantingLocalizations {
  ChantingLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String minutesPluralWithNumber(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perc',
      many: '$count perc',
      few: '$count perc',
      two: '$count perc',
      one: '$count perc',
      zero: '$count perc',
    );
    return '$_temp0';
  }

  @override
  String get statsTotal => 'Összesen';

  @override
  String get chantingTitle => 'Éneklés';

  @override
  String get chantingAddChantSheetTitle => 'Hozzáadás';

  @override
  String get chantingAddChantSheetEmptyState => 'Nincs elérhető ének.';

  @override
  String get chantingAddChantListItemAddAction => 'Hozzáadás';

  @override
  String get chantingAddChantListItemAddedAction => 'Hozzáadva';

  @override
  String get chantingPlaylistSheetTitle => 'Lejátszási lista';

  @override
  String get chantingPlaylistBadgePlaying => 'Lejátszás';

  @override
  String get chantingPlaylistBadgePaused => 'Szünet';

  @override
  String get chantingPlaylistEmptyTitle => 'A lejátszási lista üres.';

  @override
  String get chantingPlaylistEmptyDescription =>
      'Koppints a + gombra, és adj énekeket a lejátszási listához.';

  @override
  String get chantingPlayerLoading => 'Gyakorlás előkészítése...';

  @override
  String get chantingExitFinishOrDiscardTitle => 'Befejezed a gyakorlást?';

  @override
  String get chantingExitFinishOrDiscardMessage =>
      'Befejezheted most, és rögzítjük az eddig elkészült énekeket, vagy elvetheted ezt a gyakorlást.';

  @override
  String get chantingExitFinish => 'Befejezés';

  @override
  String get chantingExitDiscard => 'Elvetés';

  @override
  String get chantingExitEndSessionTitle => 'Befejezed a gyakorlást?';

  @override
  String get chantingExitEndSessionMessage =>
      'Még egy éneket sem sem fejeztél be, ezért a gyakorlat nem kerül rögzítésre.';

  @override
  String get chantingExitEndSession => 'Igen, befejezem';

  @override
  String get chantingExitCancel => 'Mégse';
}
