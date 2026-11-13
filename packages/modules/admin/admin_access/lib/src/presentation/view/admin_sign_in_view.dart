import 'package:material_ui/material_ui.dart';

import 'package:admin_access/l10n/admin_access_localizations.dart';

class AdminSignInView extends StatefulWidget {
  const AdminSignInView({super.key, this.busy = false, this.signInFailed = false, this.onSubmit});

  final bool busy;
  final bool signInFailed;
  final void Function(String email, String password)? onSubmit;

  @override
  State<AdminSignInView> createState() => _AdminSignInViewState();
}

class _AdminSignInViewState extends State<AdminSignInView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.busy || _emailController.text.trim().isEmpty || _passwordController.text.isEmpty) return;
    widget.onSubmit?.call(_emailController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AdminAccessLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('admin_sign_in'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.signInTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(l10n.signInSubtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('admin_sign_in_email'),
                  controller: _emailController,
                  enabled: !widget.busy,
                  autofocus: true,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.emailLabel, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('admin_sign_in_password'),
                  controller: _passwordController,
                  enabled: !widget.busy,
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(labelText: l10n.passwordLabel, border: const OutlineInputBorder()),
                ),
                if (widget.signInFailed) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.signInFailed,
                    key: const Key('admin_sign_in_failed'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('admin_sign_in_submit'),
                  onPressed: widget.busy ? null : _submit,
                  child: widget.busy
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.signInButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
