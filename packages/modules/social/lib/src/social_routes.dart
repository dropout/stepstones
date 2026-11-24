import 'package:core/core.dart';
import 'package:social/src/presentation/view/presence_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

part 'social_routes.g.dart';

@TypedGoRoute<PresenceRoute>(path: '/presence', name: 'PRESENCE')
class PresenceRoute extends AuthGuardedRouteData with $PresenceRoute {
  const PresenceRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => PresenceScreen();
}

List<RouteBase> $socialRoutes = [
  $presenceRoute,
];