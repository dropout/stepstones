import 'package:chanting/l10n/chanting_localizations.dart';
import 'package:chanting/src/presentation/view/exit/chanting_exit_dialog.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

void main() {
  Future<ChantingExitAction?> tapInDialog(WidgetTester tester, Widget dialog, Key buttonKey) async {
    ChantingExitAction? result;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () async => result = await showAppDialog<ChantingExitAction>(context, dialog),
              child: const Text('open'),
            ),
          ),
        ),
      ],
    );
    final services = MockServices();
    final haptics = MockHapticsService();
    when(() => services.hapticsService).thenReturn(haptics);
    await tester.pumpWidget(
      Provider<Services>.value(
        value: services,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: ChantingLocalizations.localizationsDelegates,
          supportedLocales: ChantingLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();
    return result;
  }

  group('ChantingFinishOrDiscardDialog', () {
    testWidgets('finish returns finish', (tester) async {
      final r = await tapInDialog(
        tester,
        const ChantingFinishOrDiscardDialog(),
        const Key('chanting_exit_dialog_finish_button'),
      );
      expect(r, ChantingExitAction.finish);
    });

    testWidgets('discard returns discard', (tester) async {
      final r = await tapInDialog(
        tester,
        const ChantingFinishOrDiscardDialog(),
        const Key('chanting_exit_dialog_discard_button'),
      );
      expect(r, ChantingExitAction.discard);
    });

    testWidgets('cancel returns null', (tester) async {
      final r = await tapInDialog(
        tester,
        const ChantingFinishOrDiscardDialog(),
        const Key('chanting_exit_dialog_cancel_button'),
      );
      expect(r, isNull);
    });
  });

  group('ChantingEndSessionDialog', () {
    testWidgets('confirm returns discard', (tester) async {
      final r = await tapInDialog(
        tester,
        const ChantingEndSessionDialog(),
        const Key('chanting_exit_dialog_end_button'),
      );
      expect(r, ChantingExitAction.discard);
    });

    testWidgets('cancel returns null', (tester) async {
      final r = await tapInDialog(
        tester,
        const ChantingEndSessionDialog(),
        const Key('chanting_exit_dialog_cancel_button'),
      );
      expect(r, isNull);
    });
  });
}
