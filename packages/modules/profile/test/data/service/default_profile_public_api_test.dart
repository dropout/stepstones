import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:profile/src/data/datasource/faker_profile_extension.dart';
import 'package:profile/src/data/mapper/profile_mapper.dart';
import 'package:profile/src/data/mapper/profile_session_mapper.dart';
import 'package:profile/src/data/service/default_profile_public_api.dart';
import 'package:profile/src/domain/repository/profile_repository.dart';
import 'package:profile/src/domain/repository/stats_audit_repository.dart';
import 'package:profile/src/domain/usecase/load_profile_stream_use_case.dart';
import 'package:profile/src/domain/usecase/load_profile_use_case.dart';
import 'package:profile/src/domain/usecase/update_profile_stats_with_session_use_case.dart';
import 'package:profile/src/public/model/profile_session.dart';
import 'package:profile/src/profile_di.dart';
import 'package:profile/src/public/api/profile_public_api.dart';

class MockLoadProfileUseCase extends Mock implements LoadProfileUseCase {}

class MockLoadProfileStreamUseCase extends Mock implements LoadProfileStreamUseCase {}

class MockUpdateProfileStatsWithSessionUseCase extends Mock implements UpdateProfileStatsWithSessionUseCase {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockStatsAuditRepository extends Mock implements StatsAuditRepository {}

void main() {
  late MockLoadProfileUseCase loadProfile;
  late MockLoadProfileStreamUseCase loadProfileStream;
  late MockUpdateProfileStatsWithSessionUseCase updateStats;
  late DefaultProfilePublicApi api;

  setUp(() {
    loadProfile = MockLoadProfileUseCase();
    loadProfileStream = MockLoadProfileStreamUseCase();
    updateStats = MockUpdateProfileStatsWithSessionUseCase();
    api = DefaultProfilePublicApi(
      loadProfileUseCase: loadProfile,
      loadProfileStreamUseCase: loadProfileStream,
      updateProfileStatsWithSessionUseCase: updateStats,
    );
  });

  test('loads and maps a profile with the cache preference', () async {
    final entity = Faker().createProfileEntity();
    when(() => loadProfile.execute(entity.id, preferCache: true)).thenAnswer((_) async => entity);

    expect(await api.getProfile(entity.id, preferCache: true), entity.toApi());
    verify(() => loadProfile.execute(entity.id, preferCache: true)).called(1);
  });

  test('maps profile stream events and forwards the cache filter', () async {
    final entity = Faker().createProfileEntity();
    when(() => loadProfileStream.execute(entity.id, filterCached: true)).thenAnswer((_) => Stream.value(entity));

    expect(await api.getProfileStream(entity.id, filterCached: true).toList(), [entity.toApi()]);
    verify(() => loadProfileStream.execute(entity.id, filterCached: true)).called(1);
  });

  test('maps the session and both updated profile results', () async {
    final original = Faker().createProfileEntity();
    final updated = original.copyWith(firstName: 'Updated');
    final session = ProfileSession(
      id: 'session',
      type: ProfileSessionType.chanting,
      startTime: DateTime(2026, 1, 1),
      endTime: DateTime(2026, 1, 1, 0, 10),
      duration: const Duration(minutes: 10),
    );
    when(() => updateStats.execute(original.id, session.toDomain()))
        .thenAnswer((_) async => (originalProfile: original, updatedProfile: updated));

    final result = await api.updateProfileStatsWithSession(original.id, session);

    expect(result, (originalProfile: original.toApi(), updatedProfile: updated.toApi()));
    verify(() => updateStats.execute(original.id, session.toDomain())).called(1);
  });

  test('propagates use case errors', () async {
    final error = StateError('load failed');
    when(() => loadProfile.execute('profile', preferCache: false)).thenAnswer((_) async => throw error);

    await expectLater(api.getProfile('profile'), throwsA(same(error)));
  });

  test('module DI supplies the registered use cases to the public API', () async {
    final getIt = GetIt.I;
    getIt.registerProfileModuleDependencies();
    getIt.allowReassignment = true;
    getIt.registerSingleton<ProfileRepository>(MockProfileRepository());
    getIt.registerSingleton<StatsAuditRepository>(MockStatsAuditRepository());
    addTearDown(() async {
      await getIt.reset();
      getIt.allowReassignment = false;
    });

    final resolved = getIt<ProfilePublicApi>() as DefaultProfilePublicApi;

    expect(resolved.loadProfileUseCase, same(getIt<LoadProfileUseCase>()));
    expect(resolved.loadProfileStreamUseCase, same(getIt<LoadProfileStreamUseCase>()));
    expect(resolved.updateProfileStatsWithSessionUseCase, same(getIt<UpdateProfileStatsWithSessionUseCase>()));
  });
}
