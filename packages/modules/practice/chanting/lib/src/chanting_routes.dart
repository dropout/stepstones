import 'package:assets/assets.dart';
import 'package:chanting/src/public/model/chanting_settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:chanting/src/presentation/view/chanting_screen.dart';
import 'package:core/core.dart';

part 'chanting_routes.g.dart';

@TypedGoRoute<ChantingRoute>(path: '/chanting', name: 'CHANTING')
class ChantingRoute extends GoRouteData with $ChantingRoute {
  /// Use [ChantingSettings] as extra to propagate chanting settings.
  final Object $extra;

  const ChantingRoute({required this.$extra})
    : assert($extra is ChantingSettings, 'Invalid extra data for ChantingRoute. Expected ChantingSettings.');

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final chantingSettings = $extra as ChantingSettings;
    Duration transitionDuration = Durations.long1;

    return CustomTransitionPage(
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      child: ChantingScreen(chantingSettings: chantingSettings, key: state.pageKey),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
            return LinearGradientMaskTransition(
              progress: CurvedAnimation(parent: animation, curve: Curves.easeIn),
              program: context.services.shaderService.program(Assets.shaderLinearGradientMask),
              child: child,
            );
          },
    );
  }

}

final List<RouteBase> $chantingRoutes = [$chantingRoute];
