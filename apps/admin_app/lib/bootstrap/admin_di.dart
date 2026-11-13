import 'package:admin_access/admin_access.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:firebase_provider/firebase_provider.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

extension AdminAppDependencyInjection on GetIt {
  Future<void> registerAdminDependencies({required FirebaseProvider firebaseProvider, required GoRouter router}) async {
    registerSingleton<FirebaseProvider>(firebaseProvider);
    registerSingleton<GoRouter>(router);
    await registerCoreDependencies();
    registerAuthModuleDependencies();
    registerAdminAccessModuleDependencies();
  }
}
