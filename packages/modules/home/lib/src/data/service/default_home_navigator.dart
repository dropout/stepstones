import 'package:core/core.dart';
import 'package:home/src/home_routes.dart';

class DefaultHomeNavigator extends HomeNavigator {
  DefaultHomeNavigator(super.router);

  @override
  Future<void> navigateToHome({
    int? refresh,
    NavigationType type = .push,
    bool gradientTransition = false,
  }) async => navigateTo(
    HomeRoute(refresh: refresh, gradientTransition: gradientTransition),
    type: type,
  );
}
