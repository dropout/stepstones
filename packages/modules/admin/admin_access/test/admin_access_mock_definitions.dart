import 'package:auth/auth.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_access/src/domain/repository/admin_access_repository.dart';
import 'package:admin_access/src/presentation/viewmodel/admin_access_cubit.dart';

class MockAdminAccessRepository extends Mock implements AdminAccessRepository {}

class MockAuthPublicApi extends Mock implements AuthPublicApi {}

class MockAdminAccessCubit extends MockCubit<AdminAccessState> implements AdminAccessCubit {}
