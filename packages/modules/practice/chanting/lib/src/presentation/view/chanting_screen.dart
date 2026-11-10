import 'package:chanting/src/chanting_module.dart';
import 'package:chanting/src/domain/entity/chanting_state_entity.dart';
import 'package:chanting/src/presentation/view/exit/chanting_exit_dialog.dart';
import 'package:chanting/src/presentation/viewmodel/chanting_cubit.dart';
import 'package:chanting/src/presentation/view/player/chanting_player_view.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get_it/get_it.dart';

class ChantingScreen extends StatelessWidget {
  final ChantingSettings chantingSettings;

  const ChantingScreen({required this.chantingSettings, super.key});

  @override
  Widget build(BuildContext context) {
    return SmartBlocProvider<ChantingCubit, ChantingStateEntity>(
      create: (BuildContext context) {
        return GetIt.I.get<ChantingCubit>(param1: chantingSettings)..start();
      },
      builder: (context, state) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onExitRequested(context);
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            leading: CustomBackButton(
              key: const Key('chanting_screen_back_button'),
              onPressed: () => _onExitRequested(context),
            ),
          ),
          backgroundColor: Colors.black,
          body: ChantingPlayerView(chantingState: state, wakelockService: context.services.wakelockService),
        ),
      ),
    );
  }

  Future<void> _onExitRequested(BuildContext context) async {
    final cubit = context.read<ChantingCubit>();

    // Nothing to confirm before playback has started.
    if (!cubit.state.isSessionStarted) {
      CustomBackButton.navigateBack(context);
      return;
    }

    await cubit.pauseForExitPrompt();
    if (!context.mounted) return;

    final action = await showAppDialog<ChantingExitAction>(
      context,
      cubit.state.hasCompletedChants ? const ChantingFinishOrDiscardDialog() : const ChantingEndSessionDialog(),
    );
    if (!context.mounted) return;

    switch (action) {
      case ChantingExitAction.finish:
        await cubit.finishEarly();
      case ChantingExitAction.discard:
        CustomBackButton.navigateBack(context);
      case null:
        await cubit.resumeAfterExitPrompt();
    }
  }
}
