// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'profile_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class ProfileLocalizationsHu extends ProfileLocalizations {
  ProfileLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get profile => 'Profil';

  @override
  String get sessionsHistory => 'Ülések';

  @override
  String get editProfile => 'Profil szerkesztése';

  @override
  String get donate => 'Adományozás';

  @override
  String get profileImageLabel => 'Profil kép';

  @override
  String get profileFirstnameLabel => 'Keresztnév (kötelező)';

  @override
  String get profileLastnameLabel => 'Vezetéknév (kötelező)';

  @override
  String get profileLocationLabel => 'Város';

  @override
  String get onboardingWelcomeTitle => 'Köszönjük, hogy regisztráltál!';

  @override
  String get onboardingWelcomeDescription =>
      'Fiókoddal most rendeklezésre áll: ';

  @override
  String get onboardingBenefitChanting =>
      'Fedezd fel az énekek könyvtárát, és kezdj el énekelni.';

  @override
  String get onboardingBenefitPresence =>
      'Lásd, kikkel gyakorolsz együtt az opcionális Jelenlét funkcióval.';

  @override
  String get onboardingBenefitStats =>
      'Kövesd a gyakorlásodat hasznos statisztikákkal.';

  @override
  String get onboardingCheckProfilePrompt =>
      'Először kérlek, segíts nekünk ellenőrizni, hogy helyesek-e a profilod adatai.';

  @override
  String get profileWizardTitle => 'Véglegesítsd a profilodat!';

  @override
  String get profileWizardDescription =>
      'Add meg a nevedet és profil fotódat a profil befejezéséhez és az alkalmazás teljes potenciáljának feloldásához.';

  @override
  String get profileBasicsTitle => 'Tegyük teljessé a profilodat!';

  @override
  String get profileBasicsDescription =>
      'Add meg a nevedet, és válassz profilképet, hogy mások is könnyen felismerjenek.';

  @override
  String get profileSettings => 'Beállítások';

  @override
  String get profileStats => 'Statisztika';

  @override
  String get signOut => 'Kijelentkezés';

  @override
  String get deleteProfileScreenTitle => 'Profil törlése!';

  @override
  String get deleteProfileScreenText =>
      'A profilod törléséhez biztonsági okokból újra be kell jelentkezned.';

  @override
  String get deleteProfileScreenSuccessTitle => 'A profilod\ntörölve lett!';

  @override
  String get deleteProfileScreenOkayButtonText => 'Rendben';

  @override
  String get milestones => 'Mérföldkövek';

  @override
  String get consecutiveDays => 'Egymás utáni napok';

  @override
  String get statsSignedUp => 'Csatlakozás';

  @override
  String get statsFirstSession => 'Első ülés';

  @override
  String get statsLastSession => 'Legutóbbi ülés';

  @override
  String get statsCurrentStreak => 'Aktuális sorozat';

  @override
  String get statsStartedAt => 'Aktuálist sorozat kezdete';

  @override
  String get statsNotyetStarted => 'Még nem kezdted el';

  @override
  String get statsLastCheckedAt => 'Legutolsó ellenőrzés';

  @override
  String get statsNotyetChecked => 'Még nincs ellenőrizve';

  @override
  String get statsLongestStreak => 'Leghosszabb sorozat';

  @override
  String get statsSummary => 'Összesítés';

  @override
  String get statsTotalTimeSpent => 'Összes idő';

  @override
  String get statsTotalSessions => 'Összes alkalom';

  @override
  String get statsTotalDays => 'Összes nap';

  @override
  String get statsCount => 'Darab';

  @override
  String get statsNextMilestone => 'Következő mérföldkő';

  @override
  String statsNextMilestoneIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Még $count a következő mérföldkőig.',
      many: 'Még $count a következő mérföldkőig.',
      few: 'Még $count a következő mérföldkőig.',
      two: 'Még $count a következő mérföldkőig.',
      one: 'Még $count a következő mérföldkőig.',
      zero: 'Még $count a következő mérföldkőig.',
    );
    return '$_temp0';
  }

  @override
  String statsNextMilestoneInShort(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nap múlva',
      many: '$count nap múlva',
      few: '$count nap múlva',
      two: '$count nap múlva',
      one: '$count nap múlva',
      zero: '$count nap múlva',
    );
    return '$_temp0';
  }

  @override
  String get statsNextMilestoneCompletedText =>
      'Gratulálunk az új mérföldkőhöz!';

  @override
  String sessionsPlural(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ülés',
      many: 'ülés',
      few: 'ülés',
      two: 'ülés',
      one: 'ülés',
      zero: 'ülés',
    );
    return '$_temp0';
  }

  @override
  String minutesPlural(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'perc',
      many: 'perc',
      few: 'perc',
      two: 'perc',
      one: 'perc',
      zero: 'perc',
    );
    return '$_temp0';
  }

  @override
  String daysPlural(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nap',
      many: 'nap',
      few: 'nap',
      two: 'nap',
      one: 'nap',
      zero: 'nap',
    );
    return '$_temp0';
  }

  @override
  String get notAvailableAbbr => 'N/A';

  @override
  String get showStatsOnFinishScreenTitle => 'Statisztika megjelenítése';

  @override
  String get showStatsOnFinishScreenDescription =>
      'Ha ezt a funkciót letiltod, a statisztikák nem lesznek megjelenítve az alkalmazásban.';

  @override
  String get usePresenceFeatureTitle => 'Jelenlét funkció engedélyezése';

  @override
  String get usePresenceFeatureDescription =>
      'Ha engedélyezve van, láthatod kikkel gyakorolsz együtt. Ilyenkor mások számára is látható leszel, hogy te is gyakorolsz.';

  @override
  String get clearCache => 'Gyorsítótár törlése';

  @override
  String get clearCacheDescription =>
      'Törli az összes gyorsítótárban tárolt hang- és dalszövegfájlt a mantrákhoz. Ez felszabadítja a tárhelyet, de újra le kell töltened a fájlokat, ha újra szeretnéd lejátszani őket.';

  @override
  String get healthConnect_initializingTitle_ios =>
      'Befejezett ülések mentése az\nApple Health-be';

  @override
  String get healthConnect_initializingText_ios =>
      'Szolgáltatás elérhetőségének ellenőrzése...';

  @override
  String get healthConnect_initializingTitle_android =>
      'Befejezett ülések mentése a\nGoogle Health-be';

  @override
  String get healthConnect_initializingText_android =>
      'Szolgáltatás elérhetőségének ellenőrzése...';

  @override
  String get healthConnect_serviceNotAvailableTitle_ios =>
      'Befejezett ülések mentése az\nApple Health-be';

  @override
  String get healthConnect_serviceNotAvailableText_ios =>
      'Az Apple Health szolgáltatás nem elérhető ezen az eszközön. Kérlek ellenőrizd, hogy a szolgáltatás telepítve és engedélyezve van-e.';

  @override
  String get healthConnect_serviceNotAvailableTitle_android =>
      'Befejezett ülések mentése a\nGoogle Health-be';

  @override
  String get healthConnect_serviceNotAvailableText_android =>
      'A Google Health Connect szolgáltatás nem elérhető ezen az eszközön. Kérlek ellenőrizd, hogy a szolgáltatás telepítve és engedélyezve van-e.';

  @override
  String get healthConnect_readyTitle_ios =>
      'Befejezett ülések mentése az\nApple Health-be';

  @override
  String get healthConnect_readyText_ios =>
      'Engedélyezd az Apple Health szolgáltatást, hogy a meditációra fordított időt elmenthessük és ezáltal egy helyen tarthatod az egészségügyi adataidat.';

  @override
  String get healthConnect_readyTitle_android =>
      'Befejezett ülések mentése a\nGoogle Health-be';

  @override
  String get healthConnect_readyText_android =>
      'Engedélyezd a Google Health Connect szolgáltatást, hogy a meditációra fordított időt elmenthessük és ezáltal egy helyen tarthatod az egészségügyi adataidat.';

  @override
  String get healthConnect_unnecessaryTitle_ios =>
      'Befejezett ülések mentése az\nApple Health-be';

  @override
  String get healthConnect_unnecessaryText_ios =>
      'Az Apple Health szolgáltatás már engedélyezve van, így a meditációra fordított időt már elmenthetjük az Apple Health-be.';

  @override
  String get healthConnect_unnecessaryTitle_android =>
      'Befejezett ülések mentése a\nGoogle Health-be';

  @override
  String get healthConnect_unnecessaryText_android =>
      'A Google Health Connect szolgáltatás már engedélyezve van, így a meditációra fordított időt már elmenthetjük a Google Health Connect-be.';

  @override
  String profileWizardStepLabel(int current, int total) {
    return '$current. lépés / $total';
  }

  @override
  String get profileWizardCheck => 'Ellenőrzés';

  @override
  String get profileWizardContinue => 'Tovább';

  @override
  String get profileWizardFinish => 'Befejezés';

  @override
  String get profileWizardSkip => 'Most nem';

  @override
  String get onboardingFeaturesTitle => 'Válaszd ki, mit szeretnél látni';

  @override
  String get onboardingFeaturesDescription =>
      'Két opcionális funkció alakítja a gyakorlásodat az alkalmazásban. Bármikor módosíthatod őket a Beállításokban.';

  @override
  String get onboardingStatsExplanation =>
      'A statisztikák mutatják a gyakorlással töltött időt, az egymást követő napokat és a lépőköveket. Kövesd a fejlődésedet és tartsd egyenletesen a gyakorlásod mértékét.';

  @override
  String get onboardingPresenceExplanation =>
      'A Jelenlét megmutatja, kik gyakorolnak veled egy időben. Élvezd mások gyakorlásba fektetett erőfeszítésének támogató erejét, amihez egyben a te jelenléted is hozzájárul.';

  @override
  String get locationPitchTitle => 'Nézd meg, ki gyakorol a közeledben';

  @override
  String get locationPitchBody =>
      'Add meg a városodat, és minden ülés után előre kerülnek a hozzád legközelebb gyakorlók. Csak a városodat használjuk, a pontos helyzetedet soha.';

  @override
  String get locationPromptAction => 'Város megadása';

  @override
  String get locationSavedTitle => 'Köszönjük!';

  @override
  String locationSavedBody(String city) {
    return 'Elmentve: $city.\nMostantól a hozzád legközelebb gyakorlók jelennek meg elsőként a jelenlét nézetben.';
  }
}
