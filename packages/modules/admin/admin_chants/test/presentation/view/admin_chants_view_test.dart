import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'package:admin_chants/admin_chants.dart';
import 'package:admin_chants/src/domain/entity/admin_chant_entity.dart';
import 'package:admin_chants/src/domain/enum/chant_asset_type.dart';
import 'package:admin_chants/src/presentation/view/admin_chants_view.dart';
import 'package:admin_chants/src/presentation/viewmodel/admin_chants_cubit.dart';

import '../../admin_chants_mock_definitions.dart';

void main() {
  late MockAdminChantsCubit cubit;

  const heart = AdminChantEntity(
    id: 'heart-sutra',
    name: 'Heart Sutra',
    length: Duration(minutes: 3, seconds: 5),
    playCount: 7,
    blurHash: 'LEHV6nWB2yk8',
  );
  const broken = AdminChantEntity(id: 'broken', name: 'Broken', order: 1);

  setUp(() {
    cubit = MockAdminChantsCubit();
    when(() => cubit.start()).thenAnswer((_) async {});
    when(
      () => cubit.rename(
        chantId: any(named: 'chantId'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) async {});
    when(() => cubit.dismissSaveFailure()).thenReturn(null);
    when(
      () => cubit.replaceAsset(
        chantId: any(named: 'chantId'),
        type: ChantAssetType.cover,
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpView(WidgetTester tester, AdminChantsState state, {Stream<AdminChantsState>? stream}) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    whenListen(cubit, stream ?? const Stream<AdminChantsState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AdminChantsLocalizations.localizationsDelegates,
        supportedLocales: AdminChantsLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<AdminChantsCubit>.value(value: cubit, child: const AdminChantsView()),
        ),
      ),
    );
  }

  testWidgets('shows a progress indicator while loading', (tester) async {
    await pumpView(tester, const AdminChantsState.loading());
    expect(find.byKey(const Key('admin_chants_loading')), findsOneWidget);
  });

  testWidgets('shows the error view and retries', (tester) async {
    await pumpView(tester, const AdminChantsState.error());
    expect(find.byKey(const Key('admin_chants_error')), findsOneWidget);
    await tester.tap(find.text('Retry'));
    verify(() => cubit.start()).called(1);
  });

  testWidgets('shows the empty state', (tester) async {
    await pumpView(tester, const AdminChantsState.loaded(chants: []));
    expect(find.text('No chants in the catalog yet.'), findsOneWidget);
  });

  testWidgets('lists chants with length and play count and flags a missing blurHash', (tester) async {
    await pumpView(tester, const AdminChantsState.loaded(chants: [heart, broken]));
    expect(find.text('Heart Sutra'), findsOneWidget);
    expect(find.text('3:05 · 7 plays'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    expect(find.text('Select a chant to see its details.'), findsOneWidget);
  });

  testWidgets('renames the selected chant from the detail panel', (tester) async {
    await pumpView(tester, const AdminChantsState.loaded(chants: [heart, broken]));
    await tester.tap(find.text('Heart Sutra'));
    await tester.pump();

    final save = find.byKey(const Key('admin_chant_save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('admin_chant_name')), 'Heart Sutra (new)');
    await tester.pump();
    await tester.tap(save);
    verify(() => cubit.rename(chantId: 'heart-sutra', name: 'Heart Sutra (new)')).called(1);
  });

  testWidgets('asks to replace an asset of the selected chant', (tester) async {
    await pumpView(tester, const AdminChantsState.loaded(chants: [heart, broken]));
    await tester.tap(find.text('Heart Sutra'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin_chant_replace_cover')));
    verify(() => cubit.replaceAsset(chantId: 'heart-sutra', type: ChantAssetType.cover)).called(1);
  });

  testWidgets('disables new chant and replace while saving', (tester) async {
    await pumpView(tester, const AdminChantsState.loaded(chants: [heart], saving: true));
    expect(tester.widget<FilledButton>(find.byKey(const Key('admin_chants_new'))).onPressed, isNull);
    await tester.tap(find.text('Heart Sutra'));
    await tester.pump();
    expect(tester.widget<TextButton>(find.byKey(const Key('admin_chant_replace_audio'))).onPressed, isNull);
  });

  testWidgets('warns in the detail panel when the blurHash is missing', (tester) async {
    await pumpView(tester, const AdminChantsState.loaded(chants: [heart, broken]));
    await tester.tap(find.text('Broken'));
    await tester.pump();
    expect(find.byKey(const Key('admin_chant_missing_blurhash')), findsOneWidget);
  });

  testWidgets('shows a snackbar when a save fails', (tester) async {
    const loaded = AdminChantsState.loaded(chants: [heart]);
    await pumpView(
      tester,
      loaded,
      stream: Stream.value(const AdminChantsState.loaded(chants: [heart], saveFailed: true)),
    );
    await tester.pump();
    expect(find.text('The change could not be saved.'), findsOneWidget);
    verify(() => cubit.dismissSaveFailure()).called(1);
  });
}
