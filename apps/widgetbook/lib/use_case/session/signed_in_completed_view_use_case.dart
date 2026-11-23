import 'package:material_ui/material_ui.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stepstones_widgetbook/fake_presence_scope.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:core/core.dart';
import 'package:profile/profile.dart';
import 'package:session/session.dart';

class _MockLocationPromptCubit extends MockCubit<LocationPromptState>
  implements LocationPromptCubit {}

@widgetbook.UseCase(
  name: 'Default',
  type: SignedInCompletedView,
  path: '[Session]/public/view/',
)
Widget buildSignedInCompletedView(BuildContext context) {
  final durationMinutes = context.knobs.int.slider(
    label: 'Duration (minutes)',
    initialValue: 10,
    min: 1,
    max: 120,
  );
  final type = context.knobs.object.dropdown(
    label: 'Session Type',
    options: SessionType.values,
    initialOption: SessionType.timer,
  );
  final showLocationPrompt = context.knobs.boolean(
    label: 'Show location prompt',
    initialValue: false,
  );
  final presenceOptions = FakePresenceOptions.fromKnobs(context);
  final endTime = DateTime.now();
  final profile = Profile.anonymous().copyWith(
  );

  return FakePresenceScope(
    options: presenceOptions,
    resetKey: showLocationPrompt,
    registerExtraDependencies: (sl) {
      sl.registerFactory<LocationPromptCubit>(() {
        final cubit = _MockLocationPromptCubit();
        whenListen(
          cubit,
          const Stream<LocationPromptState>.empty(),
          initialState: showLocationPrompt
            ? const LocationPromptState.prompt()
            : const LocationPromptState.hidden(),
        );
        when(cubit.load).thenAnswer((_) async {});
        when(cubit.dismiss).thenAnswer((_) async {});
        return cubit;
      });
    },
    builder: (context) => ColoredBox(
      color: Colors.black,
      child: SignedInCompletedView(
        profileId: profile.id,
        showStatsOnFinishScreen: true,
        usePresenceFeature: true,
        updateResult: UpdateProfileStatsResult(
          oldProfile: profile,
          updatedProfile: profile,
          session: Session(
            id: 'preview-session',
            type: type,
            startTime: endTime.subtract(Duration(minutes: durationMinutes)),
            endTime: endTime,
            duration: Duration(minutes: durationMinutes),
          ),
        ),
      ),
    ),
  );
}
