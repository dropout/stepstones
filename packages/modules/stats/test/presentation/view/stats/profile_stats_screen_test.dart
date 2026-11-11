import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:profile/profile.dart';
import 'package:provider/provider.dart';
import 'package:stats/src/presentation/view/profile_stats_screen.dart';
import 'package:stats/src/presentation/view/profile_stats_view.dart';
import 'package:stats/src/presentation/viewmodel/stats_bucket_cubit.dart';

import '../../../stats_mock_definitions.dart';
import '../../../stats_test_helper.dart';

void main() {
  group('ProfileStatsScreen', () {
    late MockProfileCubit profileCubit;
    late MockServices services;

    setUp(() {
      profileCubit = MockProfileCubit();
      services = MockServices();
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      setTestViewport(tester, logicalSize: const Size(1200, 1000));
      await tester.pumpWidget(
        Provider<Services>.value(
          value: services,
          child: MaterialApp(
            home: StatsTestHelper.withLocalizationProvider(
              BlocProvider<ProfileCubit>.value(
                value: profileCubit,
                child: const ShaderRenderingScope(enabled: false, child: ProfileStatsScreen(profileId: 'profile-id')),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows an empty view for the initial state', (tester) async {
      when(() => profileCubit.state).thenReturn(const ProfileState.initial());
      await pumpScreen(tester);

      expect(find.descendant(of: find.byType(ProfileStatsScreen), matching: find.byType(SizedBox)), findsOneWidget);
      expect(find.byType(ProfileStatsView), findsNothing);
      expect(find.byType(AppLoadingDisplay), findsNothing);
      expect(find.byType(AppErrorDisplay), findsNothing);
    });

    testWidgets('shows the loading display while loading', (tester) async {
      when(() => profileCubit.state).thenReturn(const ProfileState.loading());
      await pumpScreen(tester);

      expect(find.byType(AppLoadingDisplay), findsOneWidget);
      expect(find.byType(AppErrorDisplay), findsNothing);
      expect(find.byType(ProfileStatsView), findsNothing);
    });

    testWidgets('shows the error display on failure', (tester) async {
      when(() => profileCubit.state).thenReturn(const ProfileState.error());
      await pumpScreen(tester);

      expect(find.byType(AppErrorDisplay), findsOneWidget);
      expect(find.byType(AppLoadingDisplay), findsNothing);
      expect(find.byType(ProfileStatsView), findsNothing);
    });

    testWidgets('updates the displayed profile when the cubit state changes', (tester) async {
      final statsApi = MockStatsPublicApi();
      final crashlytics = MockCrashlyticsService();
      when(
        () => statsApi.queryBuckets(
          profileId: 'profile-id',
          from: any(named: 'from'),
          to: any(named: 'to'),
          granularity: .days,
        ),
      ).thenAnswer((_) async => []);
      GetIt.I.registerFactory<StatsBucketCubit>(
        () => StatsBucketCubit(statsPublicApi: statsApi, crashlyticsService: crashlytics),
      );
      addTearDown(() => GetIt.I.unregister<StatsBucketCubit>());
      final states = StreamController<ProfileState>();
      addTearDown(states.close);
      whenListen(profileCubit, states.stream, initialState: const ProfileState.loading());

      await pumpScreen(tester);
      expect(find.byType(AppLoadingDisplay), findsOneWidget);

      final profile = Profile.anonymous().copyWith(
        id: 'profile-id',
        firstName: 'Test',
        lastName: 'Profile',
        photoBlurhash: null,
      );
      states.add(ProfileState.loaded(profile: profile));
      await tester.pump();

      expect(find.byType(AppLoadingDisplay), findsNothing);
      expect(find.byType(AppErrorDisplay), findsNothing);
      expect(tester.widget<ProfileStatsView>(find.byType(ProfileStatsView)).profile, profile);
      expect(find.text('Test Profile'), findsOneWidget);

      states.add(const ProfileState.error());
      await tester.pump();
      expect(find.byType(AppErrorDisplay), findsOneWidget);
      expect(find.byType(ProfileStatsView), findsNothing);
    });
  });
}
