import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_stats/src/domain/repository/admin_stats_repository.dart';
import 'package:admin_stats/src/presentation/viewmodel/admin_stats_cubit.dart';

class MockAdminStatsRepository extends Mock implements AdminStatsRepository {}

class MockAdminStatsCubit extends MockCubit<AdminStatsState> implements AdminStatsCubit {}
