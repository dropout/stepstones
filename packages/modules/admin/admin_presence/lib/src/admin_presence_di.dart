import 'package:core/core.dart';
import 'package:firebase_provider/firebase_provider.dart';
import 'package:get_it/get_it.dart';

import 'package:admin_presence/src/data/repository/firebase_admin_presence_repository.dart';
import 'package:admin_presence/src/domain/repository/admin_presence_repository.dart';
import 'package:admin_presence/src/presentation/viewmodel/admin_presence_cubit.dart';

/// Registers the dependencies for the admin presence module; requires core.
extension AdminPresenceModuleDependencyInjection on GetIt {
  void registerAdminPresenceModuleDependencies() {
    registerLazySingleton<AdminPresenceRepository>(
      () => FirebaseAdminPresenceRepository(firestore: get<FirebaseProvider>().firestore),
    );

    registerFactory<AdminPresenceCubit>(
      () => AdminPresenceCubit(
        adminPresenceRepository: get<AdminPresenceRepository>(),
        crashlyticsService: get<CrashlyticsService>(),
      ),
    );
  }
}
