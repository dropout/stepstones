import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_presence/l10n/admin_presence_localizations.dart';
import 'package:admin_presence/src/domain/entity/admin_presence_entity.dart';
import 'package:admin_presence/src/domain/enum/admin_presence_window.dart';
import 'package:admin_presence/src/presentation/view/admin_presence_format.dart';
import 'package:admin_presence/src/presentation/viewmodel/admin_presence_cubit.dart';

class AdminPresenceView extends StatelessWidget {
  const AdminPresenceView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AdminPresenceLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<AdminPresenceCubit>();
    return BlocBuilder<AdminPresenceCubit, AdminPresenceState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.presenceTitle,
                        style: theme.textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (state is AdminPresenceLoadedState) ...[
                      Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(l10n.presenceLive, style: theme.textTheme.labelMedium),
                      const SizedBox(width: 16),
                    ],
                    SegmentedButton<AdminPresenceWindow>(
                      showSelectedIcon: false,
                      segments: [
                        for (final window in AdminPresenceWindow.values)
                          ButtonSegment(
                            value: window,
                            label: Text(
                              presenceWindowLabel(l10n, window),
                              key: Key('admin_presence_window_${window.name}'),
                            ),
                          ),
                      ],
                      selected: {state.window},
                      onSelectionChanged: (selection) => cubit.selectWindow(selection.first),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Keeps its height while loading so the list below does not jump.
                Text(
                  state is AdminPresenceLoadedState
                      ? l10n.presenceCount(state.entries.length, presenceWindowLabel(l10n, state.window))
                      : '',
                  key: const Key('admin_presence_count'),
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (state) {
              AdminPresenceLoadingState() => const Center(
                key: Key('admin_presence_loading'),
                child: CircularProgressIndicator(),
              ),
              AdminPresenceErrorState() => Center(
                key: const Key('admin_presence_error'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.presenceError),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: cubit.start, child: Text(l10n.retryButton)),
                  ],
                ),
              ),
              AdminPresenceLoadedState() => _AdminPresenceLoaded(state: state),
            },
          ),
        ],
      ),
    );
  }
}

class _AdminPresenceLoaded extends StatelessWidget {
  const _AdminPresenceLoaded({required this.state});

  final AdminPresenceLoadedState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AdminPresenceLocalizations.of(context);
    final theme = Theme.of(context);
    if (state.entries.isEmpty) {
      return Center(key: const Key('admin_presence_empty'), child: Text(l10n.presenceEmpty));
    }
    return Row(
      key: const Key('admin_presence_loaded'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.truncated)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                  child: Text(
                    l10n.presenceTruncated(AdminPresenceCubit.limit),
                    key: const Key('admin_presence_truncated'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: state.entries.length,
                  itemBuilder: (context, index) => _PresenceTile(entry: state.entries[index], now: state.now),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 300,
          child: ListView(
            key: const Key('admin_presence_locations'),
            padding: const EdgeInsets.all(24),
            children: [
              Text(l10n.byLocationTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              for (final location in state.locations)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          location.name ?? l10n.unknownLocation,
                          overflow: TextOverflow.ellipsis,
                          style: location.name == null
                              ? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                              : theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${location.count}', style: theme.textTheme.titleSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresenceTile extends StatelessWidget {
  const _PresenceTile({required this.entry, required this.now});

  final AdminPresenceEntity entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AdminPresenceLocalizations.of(context);
    final theme = Theme.of(context);
    final name = entry.displayName;
    return ListTile(
      key: ValueKey('admin_presence_${entry.profileId}'),
      leading: CircleAvatar(child: Text(name.substring(0, 1).toUpperCase())),
      title: Text(name, overflow: TextOverflow.ellipsis),
      subtitle: Text(entry.locationName ?? l10n.unknownLocation, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatPresenceAge(l10n, entry.startedAt, now), style: theme.textTheme.bodyMedium),
          Text(
            formatPresenceClock(entry.startedAt, now),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
