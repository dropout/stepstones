import 'package:core/src/navigator/base_navigator.dart';


abstract class AuthNavigator extends BaseNavigator {
  const AuthNavigator(super.router);

  /// Where guarded routes send signed-out users.
  String get loginLocation;

  Future<void> navigateToLogin({NavigationType type = .push});
  Future<void> navigateToLoginWithEmailAndPassword({NavigationType type = .push});

}
