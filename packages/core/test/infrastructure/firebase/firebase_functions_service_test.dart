import 'package:core/src/domain/entity/city_search_result.dart';
import 'package:core/src/infrastructure/firebase/firebase_functions_service.dart';
import 'package:core/src/testing/mock_definitions.dart';
import 'package:firebase_provider/firebase_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockCallableResult extends Mock implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFunctions functions;
  late MockHttpsCallable callable;
  late MockCrashlyticsService crashlytics;
  late FirebaseFunctionsService service;

  setUpAll(() {
    registerFallbackValue(HttpsCallableOptions());
  });

  setUp(() {
    functions = MockFirebaseFunctions();
    callable = MockHttpsCallable();
    crashlytics = MockCrashlyticsService();
    service = FirebaseFunctionsService(functions, crashlytics);
    when(() => functions.httpsCallable(any(), options: any(named: 'options'))).thenReturn(callable);
  });

  test('reports and rethrows callable failures once', () async {
    final error = Exception('call failed');
    when(() => callable.call<Map<String, dynamic>>(any())).thenThrow(error);

    await expectLater(service.citySearch(queryString: 'Bud'), throwsA(same(error)));

    verify(
      () => crashlytics.recordError(
        exception: error,
        stackTrace: any(named: 'stackTrace'),
        reason: 'City search failed',
      ),
    ).called(1);
  });

  test('reports malformed results and preserves empty results', () async {
    final result = MockCallableResult();
    when(() => callable.call<Map<String, dynamic>>(any())).thenAnswer((_) async => result);
    when(() => result.data).thenReturn({'results': 'invalid'});
    await expectLater(service.citySearch(queryString: 'Bud'), throwsException);
    verify(
      () => crashlytics.recordError(
        exception: any(named: 'exception'),
        stackTrace: any(named: 'stackTrace'),
        reason: 'City search failed',
      ),
    ).called(1);

    when(() => result.data).thenReturn({'results': []});
    expect(await service.citySearch(queryString: 'Bud'), isEmpty);
    verifyNever(
      () => crashlytics.recordError(
        exception: any(named: 'exception'),
        stackTrace: any(named: 'stackTrace'),
        reason: any(named: 'reason'),
      ),
    );
  });

  test('reports and rethrows location lookup failures once', () async {
    const city = CitySearchResult(placeId: 'id', name: 'Budapest', types: []);
    final error = Exception('lookup failed');
    when(() => callable.call<Map<String, dynamic>>(any())).thenThrow(error);
    await expectLater(service.getCityLocation(citySearchResult: city), throwsA(same(error)));
    verify(
      () => crashlytics.recordError(
        exception: error,
        stackTrace: any(named: 'stackTrace'),
        reason: 'City location lookup failed',
      ),
    ).called(1);
  });
}
