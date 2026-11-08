import 'package:core/core.dart';

abstract class SessionNavigator extends BaseNavigator {
  SessionNavigator(super.router);

  Future<void> navigateToSessionCompletedScreen({
    required DateTime startTime,
    required DateTime endTime,
    required Duration duration,
    required SessionType sessionType,
    List<String> completedChantIds = const [],
    NavigationType navigationType = NavigationType.push,
  });

  Future<void> navigateToSessionHistory(
    String profileId, {
    NavigationType type = NavigationType.push,
  });
  
}
