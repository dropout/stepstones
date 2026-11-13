import 'package:admin_access/admin_access.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_app/l10n/app_localizations.dart';

import 'admin_section.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.section,
    required this.account,
    required this.onSignOut,
    required this.child,
  });

  final AdminSection section;
  final AdminAccount account;
  final VoidCallback onSignOut;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('admin_shell'),
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            selectedIndex: section.index,
            onDestinationSelected: (index) => context.go(AdminSection.values[index].path),
            destinations: [
              for (final item in AdminSection.values)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label(l10n)),
                ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (account.email != null)
                        SizedBox(
                          width: 176,
                          child: Text(
                            account.email!,
                            key: const Key('admin_shell_account'),
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      TextButton.icon(
                        key: const Key('admin_shell_sign_out'),
                        onPressed: onSignOut,
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text(l10n.signOut),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
