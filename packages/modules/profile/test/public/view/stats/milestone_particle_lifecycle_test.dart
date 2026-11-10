import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particle_field/particle_field.dart';
import 'package:profile/src/public/view/stats/milestone_progress_view_item.dart';

void main() {
  Widget item(MilestoneProgressViewItemMode mode) {
    return MaterialApp(
      home: Center(
        child: SizedBox.square(dimension: 36, child: MilestoneProgressViewItem(mode: mode)),
      ),
    );
  }

  ParticleController controller(WidgetTester tester) {
    return tester.widget<ParticleField>(find.byType(ParticleField)).controller;
  }

  testWidgets('non-animated milestones settle without a particle ticker', (tester) async {
    for (final mode in [MilestoneProgressViewItemMode.incomplete, MilestoneProgressViewItemMode.completed]) {
      await tester.pumpWidget(item(mode));
      await tester.pumpAndSettle();
      expect(find.byType(ParticleField), findsNothing);
    }
  });

  testWidgets('bursts stop after particles expire and restart on tap', (tester) async {
    await tester.pumpWidget(item(MilestoneProgressViewItemMode.animate));
    final particles = controller(tester);
    expect(particles.isActive, isFalse);

    await tester.pump(const Duration(milliseconds: 256));
    await tester.pump(const Duration(milliseconds: 325));
    expect(particles.isActive, isTrue);
    expect(particles.system.count, greaterThan(0));

    await tester.pumpAndSettle();
    expect(particles.isActive, isFalse);
    expect(particles.system.count, 0);

    await tester.tap(find.byType(MilestoneProgressViewItem));
    await tester.pump(const Duration(milliseconds: 325));
    expect(particles.isActive, isTrue);
    expect(particles.system.count, greaterThan(0));

    await tester.pumpAndSettle();
    expect(particles.isActive, isFalse);
    expect(particles.system.count, 0);
  });

  testWidgets('mode changes cancel pending and active effects', (tester) async {
    await tester.pumpWidget(item(MilestoneProgressViewItemMode.animate));
    final particles = controller(tester);

    await tester.pumpWidget(item(MilestoneProgressViewItemMode.completed));
    await tester.pump(const Duration(seconds: 1));
    expect(particles.isActive, isFalse);
    expect(particles.system.count, 0);

    await tester.pumpWidget(item(MilestoneProgressViewItemMode.animate));
    await tester.pump(const Duration(milliseconds: 256));
    await tester.pump(const Duration(milliseconds: 325));
    expect(particles.isActive, isTrue);
    expect(particles.system.count, greaterThan(0));

    await tester.pumpWidget(item(MilestoneProgressViewItemMode.incomplete));
    expect(particles.isActive, isFalse);
    expect(particles.system.count, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(particles.isActive, isFalse);
    expect(particles.system.count, 0);
  });

  testWidgets('tapping before the initial delay does not replay twice', (tester) async {
    await tester.pumpWidget(item(MilestoneProgressViewItemMode.animate));
    final particles = controller(tester);

    await tester.tap(find.byType(MilestoneProgressViewItem));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 256));
    final animation =
        tester
                .widget<AnimatedBuilder>(
                  find.descendant(of: find.byType(MilestoneProgressViewItem), matching: find.byType(AnimatedBuilder)),
                )
                .animation
            as Animation<double>;
    expect(animation.value, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 325));
    expect(particles.isActive, isTrue);
    expect(particles.system.count, greaterThan(0));

    await tester.pumpAndSettle();
    expect(particles.isActive, isFalse);
    expect(particles.system.count, 0);
  });

  testWidgets('disposing cancels both pending and active effects', (tester) async {
    await tester.pumpWidget(item(MilestoneProgressViewItemMode.animate));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(item(MilestoneProgressViewItemMode.animate));
    await tester.pump(const Duration(milliseconds: 256));
    await tester.pump(const Duration(milliseconds: 325));
    expect(controller(tester).isActive, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
