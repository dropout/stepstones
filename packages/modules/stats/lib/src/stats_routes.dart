import 'package:core/core.dart';
import 'package:stats/src/presentation/view/profile_stats_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

part 'stats_routes.g.dart';

@TypedGoRoute<ProfileStatsRoute>(
  path: '/profileStats/:profileId',
  name: 'PROFILE_STATS',
)
class ProfileStatsRoute extends AuthGuardedRouteData with $ProfileStatsRoute {
  final String profileId;
  const ProfileStatsRoute({required this.profileId});
  @override
  Widget build(BuildContext context, GoRouterState state) =>
    ProfileStatsScreen(profileId: profileId);
}

List<RouteBase> $statsRoutes = [
  $profileStatsRoute,
];