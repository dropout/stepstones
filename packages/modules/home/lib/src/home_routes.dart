import 'package:assets/assets.dart';
import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import 'package:home/src/public/view/home_screen.dart';

part 'home_routes.g.dart';

@TypedGoRoute<HomeRoute>(path: '/', name: 'HOME')
class HomeRoute extends GoRouteData with $HomeRoute {
  /// An option to force home screen recreation when navigating to it,
  /// which is useful to apply changes that requires home screen reload such
  /// as timer settings change.
  final int? refresh;

  /// Reveals the home screen with the gradient sweep instead of the default
  /// page transition.
  final bool gradientTransition;

  const HomeRoute({this.refresh, this.gradientTransition = false});

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if (!gradientTransition) {
      return MaterialPage(key: state.pageKey, child: const HomeScreen());
    }
    return CustomTransitionPage(
      key: state.pageKey,
      transitionDuration: Durations.extralong4,
      reverseTransitionDuration: Durations.long1,
      child: const HomeScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => GradientTransition(
        progress: animation,
        direction: .bottomToTop,
        sweepLength: 3.0,
        wobble: 0.1,
        wobbleScale: 1.0,
        grain: 0.0,
        program: context.services.shaderService.program(Assets.shaderGradientTransitionMask),
        child: child,
      ),
    );
  }
}

List<RouteBase> $homeRoutes = [$homeRoute];
