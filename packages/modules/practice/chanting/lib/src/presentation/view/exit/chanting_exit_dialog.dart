import 'package:chanting/l10n/chanting_localizations.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

enum ChantingExitAction { finish, discard }

/// Offers to finish (logging the finished chants) or discard the session.
class ChantingFinishOrDiscardDialog extends StatelessWidget {
  const ChantingFinishOrDiscardDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = ChantingLocalizations.of(context);
    return AlertDialog(
      key: const Key('chanting_finish_or_discard_dialog'),
      title: Text(l10n.chantingExitFinishOrDiscardTitle),
      content: Text(l10n.chantingExitFinishOrDiscardMessage),
      backgroundColor: AppColors.backgroundPaperLight,
      actions: [
        DialogButton.secondary(
          key: const Key('chanting_exit_dialog_cancel_button'),
          text: l10n.chantingExitCancel,
          onPressed: () => _close(context, null),
        ),
        DialogButton.primary(
          key: const Key('chanting_exit_dialog_discard_button'),
          text: l10n.chantingExitDiscard,
          onPressed: () => _close(context, ChantingExitAction.discard),
        ),
        DialogButton(
          key: const Key('chanting_exit_dialog_finish_button'),
          text: l10n.chantingExitFinish,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          onPressed: () => _close(context, ChantingExitAction.finish),
        ),
      ],
    );
  }
}

/// Confirms ending a session that has no finished chants.
class ChantingEndSessionDialog extends StatelessWidget {
  const ChantingEndSessionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = ChantingLocalizations.of(context);
    return AlertDialog(
      key: const Key('chanting_end_session_dialog'),
      title: Text(l10n.chantingExitEndSessionTitle),
      content: Text(l10n.chantingExitEndSessionMessage),
      backgroundColor: AppColors.backgroundPaperLight,
      actions: [
        DialogButton.secondary(
          key: const Key('chanting_exit_dialog_cancel_button'),
          text: l10n.chantingExitCancel,
          onPressed: () => _close(context, null),
        ),
        DialogButton.primary(
          key: const Key('chanting_exit_dialog_end_button'),
          text: l10n.chantingExitEndSession,
          onPressed: () => _close(context, ChantingExitAction.discard),
        ),
      ],
    );
  }
}

void _close(BuildContext context, ChantingExitAction? action) {
  context.hapticsTap();
  context.pop(action);
}
