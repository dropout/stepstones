import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:profile/profile.dart';
import 'package:profile/src/data/datasource/faker_profile_extension.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:profile/src/public/view/stats/milestone_progress_view_item.dart';

import '../../../profile_test_helper.dart';
import 'particle_load_helper.dart';


void main() {
  late MockServices mockServices;
  late MockCrashlyticsService mockCrashlyticsService;

  setUpAll(() async {
    mockServices = MockServices();
    mockCrashlyticsService = MockCrashlyticsService();

    when(() => mockServices.crashlyticsService)
      .thenReturn(mockCrashlyticsService);

  });

  group('MilestoneProgressView', () {

    testWidgets('can be created with its default parameters', (WidgetTester tester) async {
      final Profile profile = Faker().createProfile();

      await tester.pumpWidget(
        ProfileTestHelper.withLocalizationProvider(
          MultiProvider(
            providers: [
              Provider<Services>.value(value: mockServices),
            ],
            child: MilestoneProgressView(
              statsReport: profile.statsReport,
            )
          ),
        )
      );
      await tester.pumpAndSettle();

      final items = tester.widgetList(find.byType(MilestoneProgressViewItem));
      List<MilestoneProgressViewItem> milestoneItems = items.map((e) => e as MilestoneProgressViewItem).toList();

      expect(find.byKey(const Key('milestone_progress_view_text')), findsOneWidget);
      expect(milestoneItems.length, 7);
      milestoneItems.asMap().forEach((index, item) {
        expect(item.mode, MilestoneProgressViewItemMode.incomplete);
      });
      expect(find.byKey(const Key('milestone_progress_view_text')), findsOneWidget);
    });

    testWidgets('can hide text if parameter is given', (WidgetTester tester) async {
      final Profile profile = Faker().createProfile();

      await tester.pumpWidget(
        ProfileTestHelper.withLocalizationProvider(
          MultiProvider(
            providers: [
              Provider<Services>.value(value: mockServices),
            ],
            child: MilestoneProgressView(
              showText: false,
              statsReport: profile.statsReport,
            )
          ),
        )
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('milestone_progress_view_text')), findsNothing);
    });

    Future<List<MilestoneProgressViewItem>> pumpAnimated(
      WidgetTester tester, {
      required int completedDaysCount,
    }) async {
      Profile profile = Faker().createProfile();
      profile = profile.copyWith(
        statsReport: profile.statsReport.copyWith(
          milestoneProgress: profile.statsReport.milestoneProgress.copyWith(
            targetDaysCount: 7,
            completedDaysCount: completedDaysCount,
          )
        )
      );

      await tester.pumpWidget(
        ProfileTestHelper.withLocalizationProvider(
          MultiProvider(
            providers: [
              Provider<Services>.value(value: mockServices),
            ],
            child: MilestoneProgressView(
              showAnimation: true,
              statsReport: profile.statsReport,
            )
          ),
        )
      );
      return tester
          .widgetList<MilestoneProgressViewItem>(find.byType(MilestoneProgressViewItem))
          .toList();
    }

    testWidgets('can show animation if parameter is given', (WidgetTester tester) async {
      final milestoneItems = await pumpAnimated(tester, completedDaysCount: 3);
      await tester.pumpAndSettle();

      expect(milestoneItems.length, 7);
      expect(milestoneItems[2].mode, MilestoneProgressViewItemMode.animate);
      expect(milestoneItems.any((item) => item.celebrate), isFalse);
    });

    testWidgets('celebrates only the item that completes the milestone', (WidgetTester tester) async {
      final milestoneItems = await pumpAnimated(tester, completedDaysCount: 7);
      await pumpUntilParticlesLoaded(tester);
      await tester.pumpAndSettle();

      expect(milestoneItems[6].mode, MilestoneProgressViewItemMode.animate);
      expect(milestoneItems[6].celebrate, isTrue);
      expect(milestoneItems.where((item) => item.celebrate).length, 1);
    });


  }); // eof group
} // eof main
