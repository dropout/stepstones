import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_presence/src/domain/repository/admin_presence_repository.dart';
import 'package:admin_presence/src/presentation/viewmodel/admin_presence_cubit.dart';

class MockAdminPresenceRepository extends Mock implements AdminPresenceRepository {}

class MockAdminPresenceCubit extends MockCubit<AdminPresenceState> implements AdminPresenceCubit {}
