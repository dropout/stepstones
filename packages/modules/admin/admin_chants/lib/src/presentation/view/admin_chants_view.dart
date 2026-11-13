import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_chants/l10n/admin_chants_localizations.dart';
import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/presentation/view/admin_chant_detail_panel.dart';
import 'package:admin_chants/src/presentation/view/admin_chant_format.dart';
import 'package:admin_chants/src/presentation/view/admin_chant_upload_dialog.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chants_cubit.dart';

class AdminChantsView extends StatefulWidget {
  const AdminChantsView({super.key});

  @override
  State<AdminChantsView> createState() => _AdminChantsViewState();
}

class _AdminChantsViewState extends State<AdminChantsView> {
  String? _selectedChantId;

  @override
  Widget build(BuildContext context) {
    final l10n = AdminChantsLocalizations.of(context);
    final cubit = context.read<AdminChantsCubit>();
    return BlocConsumer<AdminChantsCubit, AdminChantsState>(
      listenWhen: (previous, current) => current is AdminChantsLoadedState && current.saveFailed,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
        cubit.dismissSaveFailure();
      },
      builder: (context, state) => switch (state) {
        AdminChantsLoadingState() => const Center(key: Key('admin_chants_loading'), child: CircularProgressIndicator()),
        AdminChantsErrorState() => Center(
          key: const Key('admin_chants_error'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.chantsError),
              const SizedBox(height: 12),
              FilledButton(onPressed: cubit.start, child: Text(l10n.retryButton)),
            ],
          ),
        ),
        AdminChantsLoadedState(:final chants, :final saving) => _buildLoaded(context, chants, saving),
      },
    );
  }

  Widget _buildLoaded(BuildContext context, List<AdminChantEntity> chants, bool saving) {
    final l10n = AdminChantsLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<AdminChantsCubit>();
    final selected = chants.where((chant) => chant.id == _selectedChantId).firstOrNull;

    return Row(
      key: const Key('admin_chants_loaded'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  children: [
                    Text(l10n.chantsTitle, style: theme.textTheme.headlineSmall),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.chantsCount(chants.length),
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (saving)
                      const SizedBox.square(
                        key: Key('admin_chants_saving'),
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      key: const Key('admin_chants_new'),
                      onPressed: saving ? null : () => AdminChantUploadDialog.show(context, existingChants: chants),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.newChantButton),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: chants.isEmpty
                    ? Center(child: Text(l10n.chantsEmpty))
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: chants.length,
                        onReorderItem: (oldIndex, newIndex) => cubit.reorder(fromIndex: oldIndex, toIndex: newIndex),
                        itemBuilder: (context, index) {
                          final chant = chants[index];
                          return ListTile(
                            key: ValueKey('admin_chant_${chant.id}'),
                            selected: chant.id == _selectedChantId,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onTap: () => setState(() => _selectedChantId = chant.id),
                            leading: ReorderableDragStartListener(
                              index: index,
                              enabled: !saving,
                              child: const MouseRegion(
                                cursor: SystemMouseCursors.grab,
                                child: Icon(Icons.drag_indicator),
                              ),
                            ),
                            title: Text(chant.name.isEmpty ? chant.id : chant.name),
                            subtitle: Text(l10n.chantSubtitle(formatChantLength(chant.length), chant.playCount)),
                            trailing: chant.isLoadableByMobileApp
                                ? null
                                : Tooltip(
                                    message: l10n.missingBlurHash,
                                    child: Icon(Icons.warning_amber, color: theme.colorScheme.error),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 340,
          child: selected == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.selectChantHint, textAlign: TextAlign.center),
                  ),
                )
              : AdminChantDetailPanel(
                  // A new chant resets the name field.
                  key: ValueKey('admin_chant_detail_${selected.id}'),
                  chant: selected,
                  saving: saving,
                  onRename: (name) => cubit.rename(chantId: selected.id, name: name),
                  onReplaceAsset: (type) => cubit.replaceAsset(chantId: selected.id, type: type),
                ),
        ),
      ],
    );
  }
}
