import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import 'package:admin_access/src/presentation/view/admin_access_message_view.dart';
import 'package:admin_access/src/presentation/view/admin_sign_in_view.dart';
import 'package:admin_access/src/presentation/viewmodel/admin_access_cubit.dart';
import 'package:admin_access/src/public/model/admin_account.dart';
import 'package:admin_access/l10n/admin_access_localizations.dart';

typedef AdminAccessWidgetBuilder = Widget Function(BuildContext context, AdminAccount account, VoidCallback signOut);

/// Renders [builder] only for a signed-in user holding the admin claim.
class AdminAccessGate extends StatelessWidget {
  const AdminAccessGate({super.key, required this.builder});

  final AdminAccessWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminAccessCubit>(
      create: (_) => GetIt.I.get<AdminAccessCubit>()..start(),
      child: AdminAccessGateContent(builder: builder),
    );
  }
}

class AdminAccessGateContent extends StatelessWidget {
  const AdminAccessGateContent({super.key, required this.builder});

  final AdminAccessWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AdminAccessLocalizations.of(context);
    final cubit = context.read<AdminAccessCubit>();
    return BlocConsumer<AdminAccessCubit, AdminAccessState>(
      listenWhen: (previous, current) => current is AdminAccessSigningOutState,
      // Waits for the frame that disposes the admin area, so its Firestore listeners are gone before the session.
      listener: (context, state) => WidgetsBinding.instance.addPostFrameCallback((_) => cubit.completeSignOut()),
      builder: (context, state) => switch (state) {
        AdminAccessCheckingState() || AdminAccessSigningOutState() => const Scaffold(
          key: Key('admin_access_checking'),
          body: Center(child: CircularProgressIndicator()),
        ),
        AdminAccessSignedOutState(:final signInFailed) => AdminSignInView(
          signInFailed: signInFailed,
          onSubmit: (email, password) => cubit.signIn(email: email, password: password),
        ),
        AdminAccessSigningInState() => const AdminSignInView(busy: true),
        AdminAccessUnauthorizedState(:final email) => AdminAccessMessageView(
          key: const Key('admin_access_unauthorized'),
          icon: Icons.lock_outline,
          title: l10n.unauthorizedTitle,
          body: l10n.unauthorizedBody(email ?? ''),
          primaryLabel: l10n.recheckButton,
          onPrimary: cubit.recheck,
          secondaryLabel: l10n.signOutButton,
          onSecondary: cubit.signOut,
        ),
        AdminAccessErrorState() => AdminAccessMessageView(
          key: const Key('admin_access_error'),
          icon: Icons.error_outline,
          title: l10n.errorTitle,
          primaryLabel: l10n.retryButton,
          onPrimary: cubit.recheck,
          secondaryLabel: l10n.signOutButton,
          onSecondary: cubit.signOut,
        ),
        AdminAccessAuthorizedState(:final userId, :final email) => builder(
          context,
          AdminAccount(userId: userId, email: email),
          cubit.signOut,
        ),
      },
    );
  }
}
