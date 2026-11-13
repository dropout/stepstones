import 'package:admin_access/admin_access.dart';
import 'package:admin_chants/admin_chants.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'admin_section.dart';
import 'admin_shell.dart';
import 'section_placeholder.dart';

GoRouter buildAdminRouter() {
  return GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: AdminSection.chants.path,
    routes: [
      ShellRoute(
        // Every section sits behind the gate, so nothing admin-only renders before the claim is verified.
        builder: (context, state, child) => AdminAccessGate(
          builder: (context, account, signOut) => AdminShell(
            section: AdminSection.fromLocation(state.uri.path),
            account: account,
            onSignOut: signOut,
            child: child,
          ),
        ),
        routes: [
          for (final section in AdminSection.values)
            GoRoute(
              path: section.path,
              pageBuilder: (context, state) => NoTransitionPage(
                child: switch (section) {
                  AdminSection.chants => const AdminChantsScreen(),
                  _ => SectionPlaceholder(section: section),
                },
              ),
            ),
        ],
      ),
    ],
  );
}
