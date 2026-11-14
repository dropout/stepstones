import 'package:core/core.dart';
import 'package:firebase_provider/firebase_provider.dart';
import 'package:get_it/get_it.dart';

import 'package:admin_stats/src/data/repository/firebase_admin_stats_repository.dart';
import 'package:admin_stats/src/domain/repository/admin_stats_repository.dart';
import 'package:admin_stats/src/presentation/viewmodel/admin_stats_cubit.dart';

/// Registers the dependencies for the admin stats module; requires core.
extension AdminStatsModuleDependencyInjection on GetIt {
  void registerAdminStatsModuleDependencies() {
    registerLazySingleton<AdminStatsRepository>(
      () => FirebaseAdminStatsRepository(firestore: get<FirebaseProvider>().firestore),
    );

    registerFactory<AdminStatsCubit>(
      () => AdminStatsCubit(
        adminStatsRepository: get<AdminStatsRepository>(),
        crashlyticsService: get<CrashlyticsService>(),
      ),
    );
  }
}
