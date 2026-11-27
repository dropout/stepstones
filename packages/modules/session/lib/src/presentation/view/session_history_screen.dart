import '../viewmodel/sessions/sessions_cubit.dart';
import '../../../l10n/session_localizations.dart';

import 'package:core/core.dart';

import '../../public/view/session_history_list.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class const SessionHistoryScreen({required final String profileId, super.key})
    extends StatelessWidget
    with DefaultScreenSetupHelpersMixin {
  @override
  Widget build(BuildContext context) {
    return SmartBlocProvider<SessionsCubit, SessionsState>(
      create: (context) =>
        GetIt.I.get<SessionsCubit>()..loadSessions(profileId),
      builder: (context, state) => buildSessionsState(context),
    );
  }

  Widget buildSessionsState(BuildContext context) {
    return BlocBuilder<SessionsCubit, SessionsState>(
      builder: (context, state) {
        return switch (state) {
          SessionsLoaded() => DefaultScreenSetup(
              title: SessionLocalizations.of(context).sessionsHistory,
              enableAppBarSliver: false,
              slivers: [
                SliverSafeArea(
                  top: false,
                  sliver: SliverMaxwidthConstraints(
                    sliver: SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignSpec.paddingLg,
                      ),
                      sliver: SessionHistoryList(sessions: state.sessions),
                    ),
                  ),
                ),
              ],
            ),
          SessionsLoading() => DefaultScreenSetup.loading(
              title: SessionLocalizations.of(context).sessionsHistory,
            ),
          SessionsLoadingError() => DefaultScreenSetup.error(
              title: SessionLocalizations.of(context).sessionsHistory,
            ),
          _ => DefaultScreenSetup(
              title: SessionLocalizations.of(context).sessionsHistory,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              enableAppBarSliver: false,
              slivers: [],
            )
        };
      },
    );
  }
}
