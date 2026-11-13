import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_chants/src/domain/repository/admin_chant_repository.dart';
import 'package:admin_chants/src/domain/service/chant_asset_preparer.dart';
import 'package:admin_chants/src/domain/service/chant_file_picker.dart';
import 'package:admin_chants/src/domain/usecase/create_chant_use_case.dart';
import 'package:admin_chants/src/domain/usecase/replace_chant_asset_use_case.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chant_upload_cubit.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chants_cubit.dart';

class MockAdminChantRepository extends Mock implements AdminChantRepository {}

class MockChantAssetPreparer extends Mock implements ChantAssetPreparer {}

class MockChantFilePicker extends Mock implements ChantFilePicker {}

class MockCreateChantUseCase extends Mock implements CreateChantUseCase {}

class MockReplaceChantAssetUseCase extends Mock implements ReplaceChantAssetUseCase {}

class MockAdminChantsCubit extends MockCubit<AdminChantsState> implements AdminChantsCubit {}

class MockAdminChantUploadCubit extends MockCubit<AdminChantUploadState> implements AdminChantUploadCubit {}
