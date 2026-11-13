import 'package:material_ui/material_ui.dart';

import 'package:admin_app/l10n/app_localizations.dart';

enum AdminSection {
  chants('/chants', Icons.library_music_outlined, Icons.library_music),
  presence('/presence', Icons.people_outline, Icons.people),
  stats('/stats', Icons.insights_outlined, Icons.insights);

  const AdminSection(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (this) {
    chants => l10n.navChants,
    presence => l10n.navPresence,
    stats => l10n.navStats,
  };

  static AdminSection fromLocation(String location) =>
      values.firstWhere((section) => location.startsWith(section.path), orElse: () => chants);
}
