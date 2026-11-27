import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:session/src/public/view/session_history_list.dart';

import '../../session_test_helper.dart';

void main() {
  testWidgets('shows a message when the session list is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: SessionTestHelper.getLocalizationDelegates(),
        home: const Scaffold(
          body: CustomScrollView(slivers: [SessionHistoryList(sessions: [])]),
        ),
      ),
    );

    expect(find.byKey(const Key('sessions_history_empty')), findsOneWidget);
    expect(find.text('No sessions have been recorded yet.'), findsOneWidget);
  });
}
