import 'package:material_ui/material_ui.dart';

import 'package:admin_app/l10n/app_localizations.dart';

import 'admin_section.dart';

class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({super.key, required this.section});

  final AdminSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(section.icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(section.label(l10n), style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l10n.comingSoon, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
