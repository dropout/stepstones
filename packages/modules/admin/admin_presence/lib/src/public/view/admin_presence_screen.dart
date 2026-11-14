import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_presence/src/presentation/view/admin_presence_view.dart';
import 'package:admin_presence/src/presentation/viewmodel/admin_presence_cubit.dart';

class AdminPresenceScreen extends StatelessWidget {
  const AdminPresenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminPresenceCubit>(
      create: (_) => GetIt.I.get<AdminPresenceCubit>()..start(),
      child: const AdminPresenceView(),
    );
  }
}
