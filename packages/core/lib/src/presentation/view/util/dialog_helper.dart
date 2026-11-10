import 'package:material_ui/material_ui.dart';

/// A helper function to show a dialog with custom transition and styling,
/// specific to the app's design guidelines.
/// Completes with the value the dialog is popped with, or null when dismissed.
Future<T?> showAppDialog<T>(BuildContext context, Widget dialog) {
  return showGeneralDialog<T>(
    context: context,
    pageBuilder: (context, anim1, anim2) {
      return dialog;
    },
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    barrierLabel: '',
    transitionDuration: Durations.medium1,
    transitionBuilder: (context, anim1, anim2, child) {
      final curvedAnimation = CurvedAnimation(
        parent: anim1,
        curve: Curves.easeOutExpo,
      );
      return ScaleTransition(
        scale: curvedAnimation,
        child: Opacity(
          opacity: curvedAnimation.value.clamp(0.0, 1.0),
          child: child,
        ),
      );
    },
  );
}
