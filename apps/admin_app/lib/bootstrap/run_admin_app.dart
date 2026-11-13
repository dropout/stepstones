import 'package:firebase_provider/firebase_provider.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_app/app.dart';
import 'package:admin_app/shell/admin_router.dart';

import 'admin_di.dart';
import 'admin_flavor.dart';
import 'firebase_config.dart';
import 'init_error_display.dart';

Future<void> runAdminApp(AdminFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final firebaseProvider = FirebaseProvider(persistenceEnabled: !flavor.usesEmulator);
    await firebaseProvider.initialize(options: AdminFirebaseConfig.resolve(flavor));
    if (flavor.usesEmulator) {
      await firebaseProvider.useEmulator();
    }

    final router = buildAdminRouter();
    await GetIt.I.registerAdminDependencies(firebaseProvider: firebaseProvider, router: router);
    runApp(AdminApp(router: router));
  } catch (error, stackTrace) {
    debugPrint('Unable to initialize the admin app: $error\n$stackTrace');
    runApp(InitErrorDisplay(error: error));
  }
}
