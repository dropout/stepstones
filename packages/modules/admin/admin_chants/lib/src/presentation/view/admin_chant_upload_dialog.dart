import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_chants/l10n/admin_chants_localizations.dart';
import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/failure/chant_failure.dart';
import 'package:admin_chants/src/domain/usecase/create_chant_use_case.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chant_upload_cubit.dart';

class AdminChantUploadDialog extends StatelessWidget {
  const AdminChantUploadDialog({super.key, required this.existingChants});

  final List<AdminChantEntity> existingChants;

  static Future<void> show(BuildContext context, {required List<AdminChantEntity> existingChants}) {
    return showDialog<void>(
      context: context,
      // An upload in flight must not be dismissed by a stray click.
      barrierDismissible: false,
      builder: (_) => AdminChantUploadDialog(existingChants: existingChants),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminChantUploadCubit>(
      create: (_) => GetIt.I.get<AdminChantUploadCubit>(),
      child: AdminChantUploadForm(existingChants: existingChants),
    );
  }
}

class AdminChantUploadForm extends StatefulWidget {
  const AdminChantUploadForm({super.key, required this.existingChants});

  final List<AdminChantEntity> existingChants;

  @override
  State<AdminChantUploadForm> createState() => _AdminChantUploadFormState();
}

class _AdminChantUploadFormState extends State<AdminChantUploadForm> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  // The id follows the name until the admin types an id of their own.
  bool _idEdited = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  String _failureText(AdminChantsLocalizations l10n, ChantFailureReason? reason) => switch (reason) {
    null => l10n.uploadFailed,
    .emptyName => l10n.failureEmptyName,
    .nameTooLong => l10n.failureNameTooLong,
    .invalidId => l10n.failureInvalidId,
    .duplicateId => l10n.failureDuplicateId,
    .missingFile => l10n.failureMissingFile,
    .emptyFile => l10n.failureEmptyFile,
    .unreadableAsset => l10n.failureUnreadableAsset,
  };

  String _assetLabel(AdminChantsLocalizations l10n, ChantAssetType type) => switch (type) {
    .audio => l10n.detailAudio,
    .lyrics => l10n.detailLyrics,
    .cover => l10n.detailCover,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AdminChantsLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<AdminChantUploadCubit>();

    return BlocConsumer<AdminChantUploadCubit, AdminChantUploadState>(
      listenWhen: (previous, current) => current.status == AdminChantUploadStatus.completed,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final uploading = state.status != AdminChantUploadStatus.editing;
        return AlertDialog(
          key: const Key('admin_chant_upload_dialog'),
          title: Text(l10n.uploadTitle),
          // Keeps the form usable when the window is short.
          scrollable: true,
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('admin_chant_upload_name'),
                  controller: _nameController,
                  enabled: !uploading,
                  autofocus: true,
                  maxLength: CreateChantUseCase.maxNameLength,
                  decoration: InputDecoration(labelText: l10n.nameLabel, border: const OutlineInputBorder()),
                  onChanged: (name) {
                    if (!_idEdited) _idController.text = CreateChantUseCase.suggestId(name);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('admin_chant_upload_id'),
                  controller: _idController,
                  enabled: !uploading,
                  autocorrect: false,
                  maxLength: CreateChantUseCase.maxIdLength,
                  decoration: InputDecoration(
                    labelText: l10n.idLabel,
                    helperText: l10n.idHelper,
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => _idEdited = true,
                ),
                const SizedBox(height: 8),
                for (final type in ChantAssetType.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 70, child: Text(_assetLabel(l10n, type), style: theme.textTheme.bodyMedium)),
                        Expanded(
                          child: Text(
                            state.files[type]?.name ?? l10n.noFileChosen,
                            key: Key('admin_chant_upload_file_${type.name}'),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: state.files.containsKey(type) ? null : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          key: Key('admin_chant_upload_choose_${type.name}'),
                          onPressed: uploading ? null : () => cubit.pickFile(type),
                          child: Text(l10n.chooseFileButton),
                        ),
                      ],
                    ),
                  ),
                if (state.failed) ...[
                  const SizedBox(height: 12),
                  Text(
                    _failureText(l10n, state.failureReason),
                    key: const Key('admin_chant_upload_failure'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              key: const Key('admin_chant_upload_cancel'),
              onPressed: uploading ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              key: const Key('admin_chant_upload_submit'),
              onPressed: uploading
                  ? null
                  : () => cubit.submit(
                      name: _nameController.text,
                      chantId: _idController.text,
                      existingChants: widget.existingChants,
                    ),
              child: uploading
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.uploadButton),
            ),
          ],
        );
      },
    );
  }
}
