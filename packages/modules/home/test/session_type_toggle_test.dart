import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:home/src/public/enum/home_screen_view_state.dart';
import 'package:home/src/public/view/session_type_toggle.dart';

import 'home_test_helper.dart';

void main() {
  group('SessionTypeToggle', () {
    late MockServices mockServices;
    late MockHapticsService mockHapticsService;

    setUp(() {
      mockServices = MockServices();
      mockHapticsService = MockHapticsService();
      when(() => mockServices.hapticsService).thenReturn(mockHapticsService);
    });

    testWidgets('will show the correct session type toggle icon', (tester) async {
      await tester.pumpWidget(
        Provider<Services>(
          create: (context) => mockServices,
          child: HomeTestHelper.withLocalizationProvider(
            MultiBlocProvider(
              providers: [Provider<Services>(create: (context) => mockServices)],
              child: SessionTypeToggle(
                key: const ValueKey('targetWidget'),
                activeMode: .sitting,
                onModeChanged: (mode) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(HomeScreenViewState.sitting.name)), findsOneWidget);

      await tester.pumpWidget(
        Provider<Services>(
          create: (context) => mockServices,
          child: HomeTestHelper.withLocalizationProvider(
            MultiBlocProvider(
              providers: [Provider<Services>(create: (context) => mockServices)],
              child: SessionTypeToggle(
                key: const ValueKey('targetWidget'),
                activeMode: .chanting,
                onModeChanged: (mode) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey(HomeScreenViewState.chanting.name)), findsOneWidget);
    });

    testWidgets('speech bubble points to the toggle on either side of the screen', (tester) async {
      for (final alignment in [Alignment.topRight, Alignment.bottomLeft]) {
        await tester.pumpWidget(
          HomeTestHelper.withLocalizationProvider(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (_) => Align(
                      alignment: alignment,
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: SessionTypeToggle(activeMode: .sitting, onModeChanged: null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            locale: const Locale('en'),
          ),
        );

        final toggle = find.byType(SessionTypeToggle);
        await tester.tap(toggle);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Sign in to access the chanting feature.'), findsOneWidget);

        final bubble = find.byWidgetPredicate(
          (widget) => widget is DecoratedBox && widget.decoration is ShapeDecoration,
        );
        expect(bubble, findsOneWidget);
        final rect = tester.getRect(bubble);
        final button = tester.getRect(toggle);
        final shape = (tester.widget<DecoratedBox>(bubble).decoration as ShapeDecoration).shape;
        final below = rect.top >= button.bottom;
        expect(below, alignment == Alignment.topRight);
        final tipY = below ? rect.top + 2 : rect.bottom - 2;
        final path = shape.getOuterPath(rect);
        expect(path.contains(Offset(button.center.dx, tipY)), isTrue);
        expect(path.contains(Offset(button.center.dx - 16, tipY)), isFalse);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        shape.paint(canvas, Offset.zero & rect.size);
        final picture = recorder.endRecording();
        final width = rect.width.ceil();
        final pixels = await tester.runAsync(() async {
          final image = await picture.toImage(width, rect.height.ceil());
          final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          image.dispose();
          return pixels;
        });
        expect(pixels, isNotNull);
        int alphaAt(int x, int y) => pixels!.getUint8((y * width + x) * 4 + 3);

        final arrowX = (button.center.dx - rect.left).round();
        final baseY = below ? 8 : rect.height.round() - 8;
        expect(alphaAt(0, rect.height ~/ 2), greaterThan(0));
        expect(alphaAt(arrowX - 4, below ? 4 : rect.height.round() - 5), greaterThan(0));
        expect(alphaAt(arrowX, baseY), 0);
        picture.dispose();

        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}
