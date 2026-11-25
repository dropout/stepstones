import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:faker/faker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile/profile.dart';
import 'package:stats/src/data/datasource/faker_stats_extension.dart';

import 'package:stats/src/presentation/viewmodel/stats_bucket_cubit.dart';
import 'package:stats/src/public/api/stats_public_api.dart';

import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:stats/src/presentation/view/profile_stats_view.dart';
import 'package:stats/src/presentation/view/stats/tab/day_tab.dart';
import 'package:stats/src/presentation/view/stats/tab/month_tab.dart';
import 'package:stats/src/presentation/view/stats/tab/week_tab.dart';
import 'package:stats/src/presentation/view/stats/tab/year_tab.dart';

import '../../../stats_mock_definitions.dart';
import '../../../stats_test_helper.dart';


void main() {
  
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileStatsView', () {
    late MockProfileCubit mockProfileBloc;
    late StatsPublicApi mockStatsPublicApi;
    late Services mockServices;
    late CrashlyticsService mockCrashlyticsService;
    late ResourceResolver mockResourceResolver;
    
    setUp(() async {
      mockProfileBloc = MockProfileCubit();
      mockStatsPublicApi = MockStatsPublicApi();

      mockServices = MockServices();
      mockCrashlyticsService = MockCrashlyticsService();      
      mockResourceResolver = MockResourceResolver();

      GetIt.I.registerFactory<StatsBucketCubit>(() {
        return StatsBucketCubit(
          statsPublicApi: mockStatsPublicApi,
          crashlyticsService: mockCrashlyticsService,
        );
      });

      when(
        () => mockServices.resourceResolver,
      ).thenReturn(mockResourceResolver);
      when(
        () => mockResourceResolver.resolveStoragePath(any()),
      ).thenAnswer((_) async => 'https://example.com/profile.jpg');
      when(
        () => mockServices.crashlyticsService,
      ).thenReturn(mockCrashlyticsService);
      when(
        () => mockServices.hapticsService,
      ).thenReturn(MockHapticsService());

      when(
        () => mockServices.imageCacheManager,
      ).thenReturn(FakeImageCacheManager());
    });

    tearDown(() async {
      await GetIt.I.reset();
    });

    testWidgets('has all the required widgets to display', (
      WidgetTester tester,
    ) async {
      final Profile profile = Faker().createProfile();

      when(
        () => mockProfileBloc.state,
      ).thenReturn(ProfileState.loaded(profile: profile));

      await tester
          .runAsync(() async {
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  Provider<Services>(create: (_) => mockServices),
                  BlocProvider<ProfileCubit>(create: (_) => mockProfileBloc),
                ],
                child: StatsTestHelper.withLocalizationProvider(
                  Material(child: ShaderRenderingScope(
                    enabled: false,
                    child: ProfileStatsView(profile: profile))
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          })
          .then((_) async {
            expect(find.byType(DetailedProfileView), findsOneWidget);
            expect(find.byType(DetailedConsecutiveDaysView), findsOneWidget);
            expect(find.byType(DetailedMilestonesView), findsOneWidget);
            expect(find.byType(DetailedSummaryView), findsOneWidget);

            await tester.dragUntilVisible(
              find.byKey(const Key('profile_stats_tab_bar')),
              find.byKey(const Key('default_screen_setup_custom_scroll_view')),
              Offset(0, -500),
            );

            final tabBar = tester.widget<TabBar>(
              find.byKey(const Key('profile_stats_tab_bar')),
            );
            expect(tabBar.tabs.length, equals(4));
            expect(find.byType(DaysTab), findsOneWidget);
          });
    });

    testWidgets('can switch tabs', (WidgetTester tester) async {
      final Profile profile = Faker().createProfile();

      when(
        () => mockProfileBloc.state,
      ).thenReturn(ProfileState.loaded(profile: profile));

      await tester
          .runAsync(() async {
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  Provider<Services>(create: (_) => mockServices),
                  BlocProvider<ProfileCubit>(create: (_) => mockProfileBloc),
                ],
                child: StatsTestHelper.withLocalizationProvider(
                  Material(child: ShaderRenderingScope(
                    enabled: false,
                    child: ProfileStatsView(profile: profile))),
                ),
              ),
            );
            await tester.pumpAndSettle();
          })
          .then((_) async {
            expect(find.byType(DetailedProfileView), findsOneWidget);
            expect(find.byType(DetailedConsecutiveDaysView), findsOneWidget);
            expect(find.byType(DetailedMilestonesView), findsOneWidget);
            expect(find.byType(DetailedSummaryView), findsOneWidget);

            await tester.dragUntilVisible(
              find.byKey(const Key('profile_stats_tab_bar')),
              find.byKey(const Key('default_screen_setup_custom_scroll_view')),
              Offset(0, -500),
            );

            final tabBar = tester.widget<TabBar>(
              find.byKey(const Key('profile_stats_tab_bar')),
            );
            expect(tabBar.tabs.length, equals(4));
            expect(find.byType(DaysTab), findsOneWidget);

            await tester.tap(
              find.byKey(const Key('profile_stats_view_weeks_tab')),
            );
            await tester.pumpAndSettle();
            expect(find.byType(WeekTab), findsOneWidget);

            await tester.tap(
              find.byKey(const Key('profile_stats_view_months_tab')),
            );
            await tester.pumpAndSettle();
            expect(find.byType(MonthTab), findsOneWidget);

            await tester.tap(
              find.byKey(const Key('profile_stats_view_years_tab')),
            );
            await tester.pumpAndSettle();
            expect(find.byType(YearTab), findsOneWidget);
          });
    });
  }); // eof group
} // eof main
