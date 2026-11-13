import 'dart:async';

import 'package:core/l10n/core_localizations.dart';
import 'package:core/src/domain/entity/city_search_result.dart';
import 'package:core/src/presentation/view/input/form_builder_city_selector.dart';
import 'package:core/src/service/functions_service.dart';
import 'package:core/src/testing/mock_definitions.dart';
import 'package:core/src/util/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart' hide GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockFunctionsService extends Mock implements FunctionsService {}

void main() {
  late MockFunctionsService functions;
  late MockServices services;

  setUp(() {
    functions = MockFunctionsService();
    services = MockServices();
    when(() => services.functionsService).thenReturn(functions);
  });

  Future<void> showSelector(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<Services>.value(
        value: services,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            CoreLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: CitySelectorSheet(location: null, onCitySelected: null)),
        ),
      ),
    );
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 301));
  }

  testWidgets('shows failure and allows a later search', (tester) async {
    when(() => functions.citySearch(queryString: 'Bud')).thenAnswer((_) async => throw Exception('unavailable'));
    when(() => functions.citySearch(queryString: 'Paris'))
        .thenAnswer((_) async => [const CitySearchResult(placeId: 'id', name: 'Paris', types: [])]);
    await showSelector(tester);

    await search(tester, 'Bud');
    await tester.pump();
    expect(find.text('An unexpected error occured.\nPlease try again later.'), findsOneWidget);

    await search(tester, 'Paris');
    await tester.pump();
    expect(find.descendant(of: find.byType(CitySelectionCard), matching: find.text('Paris')), findsOneWidget);
  });

  testWidgets('ignores stale success and failure after the query changes', (tester) async {
    final oldSearch = Completer<List<CitySearchResult>>();
    final latestSearch = Completer<List<CitySearchResult>>();
    when(() => functions.citySearch(queryString: 'Bud')).thenAnswer((_) => oldSearch.future);
    when(() => functions.citySearch(queryString: 'Paris')).thenAnswer((_) => latestSearch.future);
    await showSelector(tester);

    await search(tester, 'Bud');
    await search(tester, 'Paris');
    latestSearch.complete([const CitySearchResult(placeId: 'id', name: 'Paris', types: [])]);
    await tester.pump();
    oldSearch.completeError(Exception('stale failure'));
    await tester.pump();
    expect(find.descendant(of: find.byType(CitySelectionCard), matching: find.text('Paris')), findsOneWidget);
    expect(find.text('An unexpected error occured.\nPlease try again later.'), findsNothing);
  });

  testWidgets('clearing the query cancels pending and ignores in-flight searches', (tester) async {
    final searchResult = Completer<List<CitySearchResult>>();
    when(() => functions.citySearch(queryString: 'Bud')).thenAnswer((_) => searchResult.future);
    await showSelector(tester);
    await search(tester, 'Bud');
    await tester.enterText(find.byType(TextField), '');
    searchResult.complete([const CitySearchResult(placeId: 'id', name: 'Budapest', types: [])]);
    await tester.pump();
    expect(find.text('Budapest'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Paris');
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 301));
    verifyNever(() => functions.citySearch(queryString: 'Paris'));
  });

  testWidgets('does not update the sheet after disposal', (tester) async {
    final searchResult = Completer<List<CitySearchResult>>();
    when(() => functions.citySearch(queryString: 'Bud')).thenAnswer((_) => searchResult.future);
    await showSelector(tester);
    await search(tester, 'Bud');
    await tester.pumpWidget(const SizedBox());
    searchResult.completeError(Exception('unavailable'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a location lookup failure', (tester) async {
    const city = CitySearchResult(placeId: 'id', name: 'Paris', types: []);
    final crashlytics = MockCrashlyticsService();
    when(() => services.crashlyticsService).thenReturn(crashlytics);
    when(() => functions.citySearch(queryString: 'Paris')).thenAnswer((_) async => [city]);
    when(() => functions.getCityLocation(citySearchResult: city))
        .thenAnswer((_) async => throw Exception('unavailable'));
    await showSelector(tester);
    await search(tester, 'Paris');
    await tester.pump();
    await tester.tap(find.byType(CitySelectionCard));
    await tester.pump();
    expect(find.text('An unexpected error occured.\nPlease try again later.'), findsOneWidget);
    verifyNever(
      () => crashlytics.recordError(
        exception: any(named: 'exception'),
        stackTrace: any(named: 'stackTrace'),
        reason: any(named: 'reason'),
      ),
    );
  });
}
