import 'package:core/src/presentation/view/util/app_context.dart';
import 'package:core/src/presentation/viewmodel/auth_state_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Base for typed routes that require a signed-in user; others are sent to login.
///
/// Extend it instead of [GoRouteData]: `class MyRoute extends AuthGuardedRouteData with $MyRoute`.
abstract class AuthGuardedRouteData extends GoRouteData {
  const AuthGuardedRouteData();

  @override
  String? redirect(BuildContext context, GoRouterState state) {
    final isSignedIn = context.read<AuthStateCubit>().state is AuthStateSignedIn;
    return isSignedIn ? null : context.services.authNavigator.loginLocation;
  }
}

extension AuthGuardRouter on GoRouter {
  /// Re-runs the visible page's redirect, so a guarded page reacts to losing auth.
  ///
  /// Used instead of [GoRouter.refresh], which skips route redirects of pages opened with push.
  Future<void> reevaluateTopRedirect(BuildContext context) async {
    if (routerDelegate.currentConfiguration.isEmpty) return;
    final current = state;
    final location = await current.topRoute?.redirect?.call(context, current);
    if (location != null && location != current.uri.toString() && context.mounted) {
      go(location);
    }
  }
}
