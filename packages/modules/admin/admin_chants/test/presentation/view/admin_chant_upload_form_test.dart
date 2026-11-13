import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_chants/admin_chants.dart';
import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/entity/picked_chant_file_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/domain/failure/chant_failure.dart';
import 'package:admin_chants/src/presentation/view/admin_chant_upload_dialog.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chant_upload_cubit.dart';

import '../../admin_chants_mock_definitions.dart';

void main() {
  late MockAdminChantUploadCubit cubit;

  const existing = [AdminChantEntity(id: 'first', name: 'First')];

  setUp(() {
    cubit = MockAdminChantUploadCubit();
    when(() => cubit.pickFile(ChantAssetType.audio)).thenAnswer((_) async {});
    when(
      () => cubit.submit(
        name: any(named: 'name'),
        chantId: any(named: 'chantId'),
        existingChants: any(named: 'existingChants'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpForm(
    WidgetTester tester,
    AdminChantUploadState state, {
    Stream<AdminChantUploadState>? stream,
  }) async {
    whenListen(cubit, stream ?? const Stream<AdminChantUploadState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AdminChantsLocalizations.localizationsDelegates,
        supportedLocales: AdminChantsLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<AdminChantUploadCubit>.value(
            value: cubit,
            child: const AdminChantUploadForm(existingChants: existing),
          ),
        ),
      ),
    );
  }

  testWidgets('suggests the id from the name until the id is edited', (tester) async {
    await pumpForm(tester, const AdminChantUploadState());
    final idField = find.byKey(const Key('admin_chant_upload_id'));

    await tester.enterText(find.byKey(const Key('admin_chant_upload_name')), 'Heart Sutra');
    expect(tester.widget<TextField>(idField).controller!.text, 'heart-sutra');

    await tester.enterText(idField, 'custom-id');
    await tester.enterText(find.byKey(const Key('admin_chant_upload_name')), 'Another Name');
    expect(tester.widget<TextField>(idField).controller!.text, 'custom-id');
  });

  testWidgets('shows chosen file names and asks the cubit to pick', (tester) async {
    await pumpForm(
      tester,
      const AdminChantUploadState(
        files: {ChantAssetType.cover: PickedChantFileEntity(path: '/tmp/c.jpg', name: 'c.jpg')},
      ),
    );
    expect(find.text('c.jpg'), findsOneWidget);
    expect(find.text('No file chosen'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('admin_chant_upload_choose_audio')));
    verify(() => cubit.pickFile(ChantAssetType.audio)).called(1);
  });

  testWidgets('submits the name, id and existing chants', (tester) async {
    await pumpForm(tester, const AdminChantUploadState());
    await tester.enterText(find.byKey(const Key('admin_chant_upload_name')), 'Heart Sutra');
    await tester.tap(find.byKey(const Key('admin_chant_upload_submit')));
    verify(() => cubit.submit(name: 'Heart Sutra', chantId: 'heart-sutra', existingChants: existing)).called(1);
  });

  testWidgets('shows the reason of a validation failure', (tester) async {
    await pumpForm(tester, const AdminChantUploadState(failed: true, failureReason: ChantFailureReason.duplicateId));
    expect(find.text('A chant with this ID already exists.'), findsOneWidget);
  });

  testWidgets('shows a generic message for an unexpected failure', (tester) async {
    await pumpForm(tester, const AdminChantUploadState(failed: true));
    expect(find.text('The upload failed. Nothing was added to the catalog.'), findsOneWidget);
  });

  testWidgets('locks the form while uploading', (tester) async {
    await pumpForm(tester, const AdminChantUploadState(status: AdminChantUploadStatus.uploading));
    expect(tester.widget<FilledButton>(find.byKey(const Key('admin_chant_upload_submit'))).onPressed, isNull);
    expect(tester.widget<TextButton>(find.byKey(const Key('admin_chant_upload_cancel'))).onPressed, isNull);
    expect(tester.widget<TextField>(find.byKey(const Key('admin_chant_upload_name'))).enabled, isFalse);
  });
}
