import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_chants/l10n/admin_chants_localizations.dart';
import 'package:admin_chants/src/domain/entity/admin_chant_asset_entity.dart';
import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/presentation/view/admin_chant_format.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chants_cubit.dart';

class AdminChantDetailPanel extends StatefulWidget {
  const AdminChantDetailPanel({
    super.key,
    required this.chant,
    required this.saving,
    required this.onRename,
    required this.onReplaceAsset,
  });

  final AdminChantEntity chant;
  final bool saving;
  final ValueChanged<String> onRename;
  final ValueChanged<ChantAssetType> onReplaceAsset;

  @override
  State<AdminChantDetailPanel> createState() => _AdminChantDetailPanelState();
}

class _AdminChantDetailPanelState extends State<AdminChantDetailPanel> {
  late final TextEditingController _nameController = TextEditingController(text: widget.chant.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AdminChantsLocalizations.of(context);
    final theme = Theme.of(context);
    final chant = widget.chant;
    final updatedAt = chant.assetsUpdatedAt;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          key: const Key('admin_chant_name'),
          controller: _nameController,
          enabled: !widget.saving,
          maxLength: AdminChantsCubit.maxNameLength,
          decoration: InputDecoration(labelText: l10n.nameLabel, border: const OutlineInputBorder()),
          onSubmitted: widget.onRename,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ListenableBuilder(
            listenable: _nameController,
            builder: (context, _) {
              final name = _nameController.text.trim();
              final canSave = !widget.saving && name.isNotEmpty && name != chant.name;
              return FilledButton(
                key: const Key('admin_chant_save'),
                onPressed: canSave ? () => widget.onRename(name) : null,
                child: Text(l10n.saveButton),
              );
            },
          ),
        ),
        if (!chant.isLoadableByMobileApp) ...[
          const SizedBox(height: 16),
          Text(
            l10n.missingBlurHash,
            key: const Key('admin_chant_missing_blurhash'),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        const Divider(),
        _DetailRow(label: l10n.detailId, value: chant.id),
        _DetailRow(label: l10n.detailLength, value: formatChantLength(chant.length)),
        _DetailRow(label: l10n.detailPlayCount, value: '${chant.playCount}'),
        for (final (type, label, asset) in [
          (ChantAssetType.audio, l10n.detailAudio, chant.audio),
          (ChantAssetType.lyrics, l10n.detailLyrics, chant.lyrics),
          (ChantAssetType.cover, l10n.detailCover, chant.cover),
        ])
          _DetailRow(
            label: label,
            value: _asset(l10n, asset),
            trailing: TextButton(
              key: Key('admin_chant_replace_${type.name}'),
              onPressed: widget.saving ? null : () => widget.onReplaceAsset(type),
              child: Text(l10n.replaceButton),
            ),
          ),
        if (updatedAt != null)
          _DetailRow(label: l10n.detailUpdated, value: DateFormat.yMMMd(l10n.localeName).add_Hm().format(updatedAt)),
      ],
    );
  }

  String _asset(AdminChantsLocalizations l10n, AdminChantAssetEntity asset) =>
      l10n.assetSummary(asset.version, formatBytes(asset.bytes));
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: trailing == null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: SelectableText(value, style: theme.textTheme.bodyMedium)),
          ?trailing,
        ],
      ),
    );
  }
}
