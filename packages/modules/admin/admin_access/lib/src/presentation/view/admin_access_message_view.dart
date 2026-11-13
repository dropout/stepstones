import 'package:material_ui/material_ui.dart';

class AdminAccessMessageView extends StatelessWidget {
  const AdminAccessMessageView({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                if (body != null) ...[
                  const SizedBox(height: 8),
                  Text(body!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: const Key('admin_access_secondary'),
                      onPressed: onSecondary,
                      child: Text(secondaryLabel),
                    ),
                    FilledButton(
                      key: const Key('admin_access_primary'),
                      onPressed: onPrimary,
                      child: Text(primaryLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
