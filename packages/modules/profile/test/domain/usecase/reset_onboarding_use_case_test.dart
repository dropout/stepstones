import 'package:core/core.dart';
import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:profile/src/data/datasource/faker_profile_extension.dart';
import 'package:profile/src/domain/usecase/reset_onboarding_use_case.dart';

import '../../profile_mock_definitions.dart';

void main() {
  setUpAll(() => registerFallbackValue(Faker().createProfileEntity()));

  test('marks profile incomplete, clears city and prompt dismissal', () async {
    final repository = MockProfileRepository();
    final preferences = MockSharedPreferencesService();
    when(() => repository.update(any())).thenAnswer(
      (_) async => Faker().createProfileEntity(),
    );
    when(() => preferences.remove(key: any(named: 'key')))
        .thenAnswer((_) async {});

    final profile = Faker().createProfileEntity().copyWith(
      completed: true,
      location: const Location(
        name: 'Budapest',
        latLng: LatLng(latitude: 47.4979, longitude: 19.0402),
        geoHash: 'u2mwd',
      ),
    );

    await ResetOnboardingUseCase(
      profileRepository: repository,
      preferences: preferences,
    ).execute(profile);

    verify(
      () => repository.update(
        profile.copyWith(completed: false, location: null),
      ),
    ).called(1);
    verify(() => preferences.remove(key: 'locationPromptDismissed')).called(1);
  });
}
