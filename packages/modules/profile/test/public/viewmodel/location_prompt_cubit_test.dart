import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:profile/src/public/viewmodel/location_prompt_cubit.dart';

class _MockPrefs extends Mock implements SharedPreferencesService {}

void main() {
  late _MockPrefs prefs;

  setUpAll(() => registerFallbackValue(SharedPreferencesKey.homeScreenState));

  setUp(() {
    prefs = _MockPrefs();
    when(
      () => prefs.set<bool>(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
  });

  test('is visible when it was never dismissed', () async {
    when(() => prefs.get<bool>(key: SharedPreferencesKey.locationPromptDismissed))
        .thenAnswer((_) async => null);
    final cubit = LocationPromptCubit(preferences: prefs);
    await cubit.load();
    expect(cubit.state, isTrue);
  });

  test('stays hidden once dismissed', () async {
    when(() => prefs.get<bool>(key: SharedPreferencesKey.locationPromptDismissed))
        .thenAnswer((_) async => true);
    final cubit = LocationPromptCubit(preferences: prefs);
    await cubit.load();
    expect(cubit.state, isFalse);
  });

  test('dismiss hides and persists', () async {
    final cubit = LocationPromptCubit(preferences: prefs)..emit(true);
    await cubit.dismiss();
    expect(cubit.state, isFalse);
    verify(
      () => prefs.set<bool>(
        key: SharedPreferencesKey.locationPromptDismissed,
        value: true,
      ),
    ).called(1);
  });
}
