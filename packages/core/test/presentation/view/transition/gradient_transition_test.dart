import 'dart:ui';

import 'package:assets/assets.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FragmentProgram maskProgram;

  setUpAll(() async {
    maskProgram = await FragmentProgram.fromAsset(Assets.shaderGradientTransitionMask);
  });

  Widget harness(
    Animation<double> progress, [
    GradientTransitionDirection direction = GradientTransitionDirection.topToBottom,
  ]) => Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: 100,
      height: 100,
      child: GradientTransition.switcher(
        progress: progress,
        program: maskProgram,
        direction: direction,
        from: const ColoredBox(color: Colors.red),
        to: const ColoredBox(color: Colors.blue),
      ),
    ),
  );

  testWidgets('renders at start, middle and end of the transition', (tester) async {
    final controller = AnimationController(vsync: tester, duration: const Duration(seconds: 1));
    addTearDown(controller.dispose);

    for (final direction in GradientTransitionDirection.values) {
      await tester.pumpWidget(harness(controller, direction));
      for (final value in [0.0, 0.5, 1.0]) {
        controller.value = value;
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }
    expect(find.byType(ShaderMask), findsOneWidget);
  });

  testWidgets('each transition masks with its own shader instance', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            for (final value in [1.0, 0.3])
              SizedBox(
                width: 100,
                height: 50,
                child: GradientTransition(
                  progress: AlwaysStoppedAnimation(value),
                  program: maskProgram,
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );

    final masks = tester.widgetList<ShaderMask>(find.byType(ShaderMask));
    const rect = Rect.fromLTWH(0, 0, 100, 50);
    final shaders = masks.map((m) => m.shaderCallback(rect)).toList();
    expect(shaders, hasLength(2));
    expect(identical(shaders[0], shaders[1]), isFalse);
  });
}
