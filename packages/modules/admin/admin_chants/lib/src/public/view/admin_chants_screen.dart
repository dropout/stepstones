import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_chants/src/presentation/view/admin_chants_view.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chants_cubit.dart';

class AdminChantsScreen extends StatelessWidget {
  const AdminChantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminChantsCubit>(
      create: (_) => GetIt.I.get<AdminChantsCubit>()..start(),
      child: const AdminChantsView(),
    );
  }
}
