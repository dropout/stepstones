import 'package:core/core.dart';
import 'package:firebase_provider/firebase_provider.dart';
import 'package:get_it/get_it.dart';

import 'package:admin_chants/src/data/repository/firebase_admin_chant_repository.dart';
import 'package:admin_chants/src/data/service/default_chant_asset_preparer.dart';
import 'package:admin_chants/src/data/service/file_selector_chant_file_picker.dart';
import 'package:admin_chants/src/data/service/so_loud_audio_length_reader.dart';
import 'package:admin_chants/src/domain/repository/admin_chant_repository.dart';
import 'package:admin_chants/src/domain/service/chant_asset_preparer.dart';
import 'package:admin_chants/src/domain/service/chant_file_picker.dart';
import 'package:admin_chants/src/domain/usecase/create_chant_use_case.dart';
import 'package:admin_chants/src/domain/usecase/replace_chant_asset_use_case.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chant_upload_cubit.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chants_cubit.dart';

/// Registers the dependencies for the admin chants module; requires core.
extension AdminChantsModuleDependencyInjection on GetIt {
  void registerAdminChantsModuleDependencies() {
    // Platform services
    registerLazySingleton<ChantFilePicker>(FileSelectorChantFilePicker.new);
    registerLazySingleton<ChantAssetPreparer>(
      () => const DefaultChantAssetPreparer(readAudioLength: readAudioLengthWithSoLoud),
    );

    // Repositories
    registerLazySingleton<AdminChantRepository>(
      () => FirebaseAdminChantRepository(
        firestore: get<FirebaseProvider>().firestore,
        storage: get<FirebaseProvider>().storage,
      ),
    );

    // Use cases
    registerFactory<CreateChantUseCase>(
      () => CreateChantUseCase(
        chantAssetPreparer: get<ChantAssetPreparer>(),
        adminChantRepository: get<AdminChantRepository>(),
      ),
    );
    registerFactory<ReplaceChantAssetUseCase>(
      () => ReplaceChantAssetUseCase(
        chantAssetPreparer: get<ChantAssetPreparer>(),
        adminChantRepository: get<AdminChantRepository>(),
      ),
    );

    // Cubits
    registerFactory<AdminChantsCubit>(
      () => AdminChantsCubit(
        adminChantRepository: get<AdminChantRepository>(),
        replaceChantAssetUseCase: get<ReplaceChantAssetUseCase>(),
        chantFilePicker: get<ChantFilePicker>(),
        crashlyticsService: get<CrashlyticsService>(),
      ),
    );
    registerFactory<AdminChantUploadCubit>(
      () => AdminChantUploadCubit(
        createChantUseCase: get<CreateChantUseCase>(),
        chantFilePicker: get<ChantFilePicker>(),
        crashlyticsService: get<CrashlyticsService>(),
      ),
    );
  }
}
