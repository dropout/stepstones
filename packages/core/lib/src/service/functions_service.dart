import 'package:core/src/domain/entity/city_search_result.dart';


abstract interface class FunctionsService {

  const FunctionsService();

  /// Returns matching cities, or throws if the search fails.
  Future<List<CitySearchResult>> citySearch({
    required String queryString,
  });

  /// Returns the city with its location, or throws if the lookup fails.
  Future<CitySearchResult> getCityLocation({
    required CitySearchResult citySearchResult,
  });

}
