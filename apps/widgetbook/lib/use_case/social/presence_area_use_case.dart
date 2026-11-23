import 'package:material_ui/material_ui.dart';
import 'package:social/social.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:core/core.dart';
import 'package:stepstones_widgetbook/fake_presence_scope.dart';

@widgetbook.UseCase(
  name: 'Fake data provider',
  type: PresenceArea,
  path: '[Social]/public/view/',
)
Widget buildPresenceArea(BuildContext context) {
  final options = FakePresenceOptions.fromKnobs(context);
  final batchSize = context.knobs.int.slider(
    label: 'Batch size',
    initialValue: 18,
    min: 3,
    max: 30,
  );

  return FakePresenceScope(
    options: options,
    resetKey: batchSize,
    builder: (context) => ColoredBox(
      color: Colors.black,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignSpec.paddingLg),
        // Mirrors the call in SignedInCompletedView.
        child: PresenceArea.withCubit(
          profileId: 'preview-own-profile',
          batchSize: batchSize,
          onCubitCreated: (cubit) => cubit.loadPresenceData(
            ownProfileId: 'preview-own-profile',
            limit: batchSize,
            windowSize: const Duration(minutes: 120),
          ),
        ),
      ),
    ),
  );
}
