import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:firebase_provider/firebase_provider.dart';
import 'package:get_it/get_it.dart';

import 'package:admin_access/src/data/repository/firebase_admin_access_repository.dart';
import 'package:admin_access/src/domain/repository/admin_access_repository.dart';
import 'package:admin_access/src/presentation/viewmodel/admin_access_cubit.dart';

/// Registers the dependencies for the admin access module; requires core and auth.
extension AdminAccessModuleDependencyInjection on GetIt {
  void registerAdminAccessModuleDependencies() {
    registerLazySingleton<AdminAccessRepository>(() => FirebaseAdminAccessRepository(get<FirebaseProvider>().auth));

    registerFactory<AdminAccessCubit>(
      () => AdminAccessCubit(
        adminAccessRepository: get<AdminAccessRepository>(),
        authApi: get<AuthPublicApi>(),
        crashlyticsService: get<CrashlyticsService>(),
      ),
    );
  }
}
