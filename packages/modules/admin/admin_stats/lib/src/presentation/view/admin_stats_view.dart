import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_stats/l10n/admin_stats_localizations.dart';
import 'package:admin_stats/src/domain/entity/daily_global_stats_entity.dart';
import 'package:admin_stats/src/domain/entity/global_stats_entity.dart';
import 'package:admin_stats/src/domain/enum/admin_stats_range.dart';
import 'package:admin_stats/src/presentation/view/admin_stats_format.dart';
import 'package:admin_stats/src/presentation/viewmodel/admin_stats_cubit.dart';

class AdminStatsView extends StatelessWidget {
  const AdminStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AdminStatsLocalizations.of(context);
    final cubit = context.read<AdminStatsCubit>();
    return BlocBuilder<AdminStatsCubit, AdminStatsState>(
      builder: (context, state) => switch (state) {
        AdminStatsLoadingState() => const Center(key: Key('admin_stats_loading'), child: CircularProgressIndicator()),
        AdminStatsErrorState() => Center(
          key: const Key('admin_stats_error'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.statsError),
              const SizedBox(height: 12),
              FilledButton(onPressed: cubit.start, child: Text(l10n.retryButton)),
            ],
          ),
        ),
        AdminStatsLoadedState() => _AdminStatsLoaded(state: state),
      },
    );
  }
}

class _AdminStatsLoaded extends StatelessWidget {
  const _AdminStatsLoaded({required this.state});

  final AdminStatsLoadedState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AdminStatsLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<AdminStatsCubit>();
    final dailyLoading = state.dailyStatus == AdminStatsDailyStatus.loading;
    final hasDays = state.days.isNotEmpty;

    return ListView(
      key: const Key('admin_stats_loaded'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.statsTitle, style: theme.textTheme.headlineSmall, overflow: TextOverflow.ellipsis),
            ),
            if (dailyLoading)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox.square(
                  key: Key('admin_stats_daily_loading'),
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              key: const Key('admin_stats_refresh'),
              tooltip: l10n.refreshButton,
              onPressed: dailyLoading ? null : cubit.refresh,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
            SegmentedButton<AdminStatsRange>(
              showSelectedIcon: false,
              segments: [
                for (final range in AdminStatsRange.values)
                  ButtonSegment(
                    value: range,
                    label: Text(statsRangeLabel(l10n, range), key: Key('admin_stats_range_${range.name}')),
                  ),
              ],
              selected: {state.range},
              onSelectionChanged: (selection) => cubit.selectRange(selection.first),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.allTime.totalSessions == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(l10n.noSessionsYet, key: const Key('admin_stats_empty'), style: theme.textTheme.bodyMedium),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SummaryCard(
                key: const Key('admin_stats_all_time'),
                title: l10n.allTimeTitle,
                stats: state.allTime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                key: const Key('admin_stats_today'),
                title: l10n.todayTitle,
                stats: hasDays ? state.today : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                key: const Key('admin_stats_range'),
                title: l10n.rangeTitle(state.range.days),
                stats: hasDays ? state.rangeTotal : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.dailyTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (state.dailyStatus == AdminStatsDailyStatus.failed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.dailyFailed,
              key: const Key('admin_stats_daily_failed'),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (!hasDays && dailyLoading)
          Text(l10n.dailyLoading, style: theme.textTheme.bodyMedium)
        else if (hasDays) ...[
          _DailyBars(days: state.days),
          const SizedBox(height: 16),
          _DailyTable(days: state.days),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({super.key, required this.title, required this.stats});

  final String title;

  /// Null while the numbers are still loading.
  final GlobalStatsEntity? stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AdminStatsLocalizations.of(context);
    final theme = Theme.of(context);
    final stats = this.stats;
    final types = stats == null ? const <String>[] : (stats.sessionsByType.keys.toList()..sort());
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            if (stats == null)
              Text('–', style: theme.textTheme.headlineSmall)
            else ...[
              Text(l10n.sessionsCount(stats.totalSessions), style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                l10n.practiceTime(formatStatsDuration(l10n, stats.totalDuration)),
                style: theme.textTheme.bodyMedium,
              ),
              if (types.isNotEmpty) const SizedBox(height: 8),
              for (final type in types)
                Text(
                  l10n.typeBreakdown(statsSessionTypeLabel(l10n, type), stats.sessionsByType[type]!),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.days});

  final List<DailyGlobalStatsEntity> days;

  @override
  Widget build(BuildContext context) {
    final l10n = AdminStatsLocalizations.of(context);
    final theme = Theme.of(context);
    final peak = days.fold(0, (max, day) => day.stats.totalSessions > max ? day.stats.totalSessions : max);
    return SizedBox(
      key: const Key('admin_stats_bars'),
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final day in days)
            Expanded(
              child: Tooltip(
                message: l10n.dayTooltip(formatStatsDay(day.day), day.stats.totalSessions),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      // An empty day keeps a hairline so the time axis stays readable.
                      heightFactor: peak == 0 || day.stats.totalSessions == 0 ? 0.01 : day.stats.totalSessions / peak,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: day.stats.totalSessions == 0
                              ? theme.colorScheme.outlineVariant
                              : theme.colorScheme.primary,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DailyTable extends StatelessWidget {
  const _DailyTable({required this.days});

  final List<DailyGlobalStatsEntity> days;

  @override
  Widget build(BuildContext context) {
    final l10n = AdminStatsLocalizations.of(context);
    final theme = Theme.of(context);
    final header = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    // Only days with sessions are listed; the chart above already shows the gaps.
    final active = [
      for (final day in days.reversed)
        if (day.stats.totalSessions > 0) day,
    ];

    Widget row(String day, String sessions, String time, TextStyle? style) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(day, style: style)),
          Expanded(
            child: Text(sessions, style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 2,
            child: Text(time, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );

    return Column(
      key: const Key('admin_stats_table'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(l10n.dayColumn, l10n.sessionsColumn, l10n.timeColumn, header),
        const Divider(height: 8),
        for (final day in active)
          row(
            formatStatsDay(day.day),
            '${day.stats.totalSessions}',
            formatStatsDuration(l10n, day.stats.totalDuration),
            theme.textTheme.bodyMedium,
          ),
      ],
    );
  }
}
