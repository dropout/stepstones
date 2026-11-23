import 'package:flutter_test/flutter_test.dart';
import 'package:particle_field/particle_field.dart';

/// Waits for the async star sprite load, which needs real I/O and decoding.
Future<void> pumpUntilParticlesLoaded(WidgetTester tester) async {
  for (var i = 0; i < 100 && find.byType(ParticleField).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
  expect(find.byType(ParticleField), findsOneWidget);
}
