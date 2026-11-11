import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:timer/src/public/view/timer_settings/warmup_input.dart';
import 'package:timer/src/public/view/timer_settings/warmup_input_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../timer_test_helper.dart';

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  setUpAll(() {
    // to be able to use WidgetBuilder
    // in modal content with fake context
    registerFallbackValue(FakeBuildContext());
  });

  group('WarmupTimeInput', () {
    testWidgets('render with initial value', (WidgetTester tester) async {
      MockOverlayService mockOverlayService = MockOverlayService();

      await tester.pumpWidget(
        TimerTestHelper.withLocalizationProvider(
          WarmupInput(label: 'Test label', value: Duration(minutes: 3), overlayService: mockOverlayService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('3 perc'), findsOneWidget);
      expect(find.byKey(Key('warmup_input_button')), findsOneWidget);
    });

    testWidgets('opens modal on button tap', (WidgetTester tester) async {
      MockOverlayService mockOverlayService = MockOverlayService();
      when(
        () => mockOverlayService.showModalBottomSheet(
          any(that: isA<BuildContext>()),
          any(that: isA<WidgetBuilder>()),
          enableDrag: false,
        ),
      ).thenAnswer((_) async => null);

      MockHapticsService mockHapticsService = MockHapticsService();

      MockServices mockServices = MockServices();
      when(() => mockServices.hapticsService).thenReturn(mockHapticsService);

      await tester.pumpWidget(
        Provider<Services>(
          create: (_) => mockServices,
          child: MaterialApp(
            home: Scaffold(
              body: TimerTestHelper.withLocalizationProvider(
                WarmupInput(label: 'Test label', value: Duration(minutes: 3), overlayService: mockOverlayService),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(Key('warmup_input_button')));
      await tester.pumpAndSettle();

      final builder =
          verify(
                () => mockOverlayService.showModalBottomSheet(
                  any(that: isA<BuildContext>()),
                  captureAny(that: isA<WidgetBuilder>()),
                  enableDrag: false,
                ),
              ).captured.single
              as WidgetBuilder;

      final view = builder(tester.element(find.byType(WarmupInput))) as WarmupInputView;
      expect(view.title, 'Test label');
      expect(view.initialValue, 3);
    });
  });

  testWidgets('warmup options show the selection and save the selected duration', (tester) async {
    setTestViewport(tester);
    final mockServices = MockServices();
    final mockHapticsService = MockHapticsService();
    when(() => mockServices.hapticsService).thenReturn(mockHapticsService);
    Duration? selectedDuration;

    await tester.pumpWidget(
      Provider<Services>.value(
        value: mockServices,
        child: MaterialApp(
          home: Scaffold(
            body: TimerTestHelper.withLocalizationProvider(
              WarmupInputView(title: 'Warmup', initialValue: 3, onSelect: (duration) => selectedDuration = duration),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder option(int minutes) =>
        find.ancestor(of: find.text('$minutes'), matching: find.byType(GestureDetector)).first;

    double checkmarkOpacity(int minutes) {
      final opacity = find.descendant(of: option(minutes), matching: find.byType(AnimatedOpacity));
      return tester.widget<AnimatedOpacity>(opacity).opacity;
    }

    for (final minutes in [0, 1, 2, 3, 5]) {
      expect(find.text('$minutes'), findsOneWidget);
      expect(checkmarkOpacity(minutes), minutes == 3 ? 1 : 0);
    }

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    for (final minutes in [0, 1, 2, 3, 5]) {
      expect(checkmarkOpacity(minutes), minutes == 5 ? 1 : 0);
    }
    verify(() => mockHapticsService.select()).called(1);

    await tester.tap(find.byKey(const Key('input_view_save_button')));
    await tester.pumpAndSettle();
    expect(selectedDuration, const Duration(minutes: 5));
  });
}
