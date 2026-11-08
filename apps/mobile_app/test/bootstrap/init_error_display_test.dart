import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/bootstrap/init_error_display.dart';

void main() {
  testWidgets('displays the initialization error in English', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const InitErrorDisplay());
    await tester.pumpAndSettle();

    expect(find.text('Unexpected Error'), findsOneWidget);
    expect(find.text('The app failed to initialize. Please try again later.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('displays the initialization error in Hungarian', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = [const Locale('hu', 'HU')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const InitErrorDisplay());
    await tester.pumpAndSettle();

    expect(find.text('Váratlan hiba!'), findsOneWidget);
    expect(find.text('Nem sikerült elindítani az alkalmazást. Kérlek próbáld újra később.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to English for an unsupported locale', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = [const Locale('fr')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const InitErrorDisplay());
    await tester.pumpAndSettle();

    expect(find.text('Unexpected Error'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
