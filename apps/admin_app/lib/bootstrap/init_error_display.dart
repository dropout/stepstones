import 'package:material_ui/material_ui.dart';

import 'package:admin_app/l10n/app_localizations.dart';

class InitErrorDisplay extends StatelessWidget {
  const InitErrorDisplay({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).initErrorTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  SelectableText(error.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
