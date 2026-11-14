import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_stats/src/presentation/view/admin_stats_view.dart';
import 'package:admin_stats/src/presentation/viewmodel/admin_stats_cubit.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminStatsCubit>(
      create: (_) => GetIt.I.get<AdminStatsCubit>()..start(),
      child: const AdminStatsView(),
    );
  }
}
