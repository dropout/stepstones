import 'package:core/core.dart';
import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:profile/src/data/datasource/faker_profile_extension.dart';
import 'package:profile/src/data/mapper/profile_mapper.dart';
import 'package:profile/src/public/viewmodel/location_prompt_cubit.dart';

import '../../profile_mock_definitions.dart';

class _MockPrefs extends Mock implements SharedPreferencesService {}

void main() {
  late _MockPrefs prefs;
  late MockUpdateProfileUseCase updateProfileUseCase;
  late MockCrashlyticsService crashlyticsService;

  const location = Location(
    name: 'Budapest',
    latLng: LatLng(latitude: 47.4979, longitude: 19.0402),
    geoHash: 'u2mw1q8x',
  );

  LocationPromptCubit buildCubit() => LocationPromptCubit(
    preferences: prefs,
    updateProfileUseCase: updateProfileUseCase,
    crashlyticsService: crashlyticsService,
  );

  setUpAll(() => registerFallbackValue(SharedPreferencesKey.homeScreenState));

  setUp(() {
    prefs = _MockPrefs();
    updateProfileUseCase = MockUpdateProfileUseCase();
    crashlyticsService = MockCrashlyticsService();
    when(
      () => prefs.set<bool>(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => crashlyticsService.recordError(
        exception: any(named: 'exception'),
        stackTrace: any(named: 'stackTrace'),
        reason: any(named: 'reason'),
      ),
    ).thenReturn(null);
  });

  test('is visible when it was never dismissed', () async {
    when(() => prefs.get<bool>(key: SharedPreferencesKey.locationPromptDismissed))
        .thenAnswer((_) async => null);
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state, const LocationPromptState.prompt());
  });

  test('stays hidden once dismissed', () async {
    when(() => prefs.get<bool>(key: SharedPreferencesKey.locationPromptDismissed))
        .thenAnswer((_) async => true);
    final cubit = buildCubit();
    await cubit.load();
    expect(cubit.state, const LocationPromptState.hidden());
  });

  test('dismiss hides and persists', () async {
    final cubit = buildCubit()..emit(const LocationPromptState.prompt());
    await cubit.dismiss();
    expect(cubit.state, const LocationPromptState.hidden());
    verify(
      () => prefs.set<bool>(
        key: SharedPreferencesKey.locationPromptDismissed,
        value: true,
      ),
    ).called(1);
  });

  group('saveLocation', () {
    final profileEntity = Faker().createProfileEntity();

    test('saves the location, thanks the user and persists the prompt', () async {
      when(
        () => updateProfileUseCase.execute(
          profile: profileEntity,
          updatedFields: {'location': location},
        ),
      ).thenAnswer((_) async => profileEntity.copyWith(location: location));
      final cubit = buildCubit()..emit(const LocationPromptState.prompt());

      final saved = await cubit.saveLocation(
        profile: profileEntity.toApi(),
        location: location,
      );

      expect(saved, isTrue);
      expect(cubit.state, const LocationPromptState.saved(location: location));
      verify(
        () => prefs.set<bool>(
          key: SharedPreferencesKey.locationPromptDismissed,
          value: true,
        ),
      ).called(1);
    });

    test('stays visible and reports the error on failure', () async {
      when(
        () => updateProfileUseCase.execute(
          profile: profileEntity,
          updatedFields: {'location': location},
        ),
      ).thenThrow(Exception('offline'));
      final cubit = buildCubit()..emit(const LocationPromptState.prompt());

      final saved = await cubit.saveLocation(
        profile: profileEntity.toApi(),
        location: location,
      );

      expect(saved, isFalse);
      expect(cubit.state, const LocationPromptState.prompt());
      verifyNever(
        () => prefs.set<bool>(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
      verify(
        () => crashlyticsService.recordError(
          exception: any(named: 'exception'),
          stackTrace: any(named: 'stackTrace'),
          reason: any(named: 'reason'),
        ),
      ).called(1);
    });
  });
}
