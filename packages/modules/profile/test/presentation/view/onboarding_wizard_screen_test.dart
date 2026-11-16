import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:faker/faker.dart';
import 'package:get_it/get_it.dart';
import 'package:profile/l10n/profile_localizations.dart';
import 'package:profile/src/data/datasource/faker_profile_extension.dart';
import 'package:profile/src/presentation/view/form_builder_profile_image_picker.dart';
import 'package:profile/src/presentation/view/profile_basics_fields.dart';
import 'package:profile/src/presentation/view/profile_location_field.dart';
import 'package:profile/src/presentation/view/wizard/onboarding_wizard_step_indicator.dart';
import 'package:profile/src/presentation/view/screen/onboarding_wizard_screen.dart';

import 'package:profile/src/presentation/viewmodel/profile_edit_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart'
    show AnimatedSwitcher, EditableText, Key, Locale, Offset, Overlay, OverlayEntry, Size, Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:profile/src/public/model/profile.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../profile_mock_definitions.dart';
import '../../profile_test_helper.dart';

void main() {
  group('OnboardingWizardScreen Tests', () {
    late MockProfileEditCubit mockProfileEditCubit;
    late Services mockServices;
    late CrashlyticsService mockCrashlyticsService;
    late HapticsService mockHapticsService;

    setUpAll(() {
      registerFallbackValue(ProfileEditState.initial());
      registerFallbackValue(Faker().createProfile());
    });

    setUp(() {
      GetIt.I.registerFactory<ProfileEditCubit>(
        () => mockProfileEditCubit,
      );

      mockProfileEditCubit = MockProfileEditCubit();
      mockCrashlyticsService = MockCrashlyticsService();
      mockHapticsService = MockHapticsService();
      mockServices = MockServices();

      when(() => mockServices.crashlyticsService)
          .thenReturn(mockCrashlyticsService);
      when(() => mockServices.hapticsService).thenReturn(mockHapticsService);
      when(() => mockServices.analyticsService)
          .thenReturn(MockAnalyticsService());
      when(() => mockHapticsService.tap()).thenReturn(null);
      when(() => mockHapticsService.success()).thenReturn(null);
      when(() => mockHapticsService.error()).thenReturn(null);
    });

    tearDown(() {
      GetIt.I.reset();
    });

    testWidgets('will load profile on init', (WidgetTester tester) async {
      when(() => mockProfileEditCubit.state)
          .thenReturn(ProfileEditState.initial());
      when(() => mockProfileEditCubit.stream).thenAnswer(
        (_) =>
            Stream<ProfileEditState>.fromIterable([ProfileEditState.initial()]),
      );

      await tester.pumpWidget(
        ProfileTestHelper.withLocalizationProvider(
          BlocProvider<ProfileEditCubit>(
            create: (context) => mockProfileEditCubit,
            child: ShaderRenderingScope(
              enabled: false,
              child: OnboardingWizardScreen(profileId: 'test_profile_id')
            ),
          ),
        ),
      );

      verify(() => mockProfileEditCubit.loadProfile('test_profile_id'))
          .called(1);
    });

    testWidgets('can display a loading state', (WidgetTester tester) async {
      when(() => mockProfileEditCubit.state)
          .thenReturn(ProfileEditState.loading());
      when(() => mockProfileEditCubit.stream).thenAnswer(
        (_) =>
            Stream<ProfileEditState>.fromIterable([ProfileEditState.loading()]),
      );

      await tester.pumpWidget(
        ProfileTestHelper.withLocalizationProvider(
          BlocProvider<ProfileEditCubit>(
            create: (context) => mockProfileEditCubit,
            child: ShaderRenderingScope(
              enabled: false,
              child: OnboardingWizardScreen(profileId: 'test_profile_id'),
            ),
          ),
        ),
      );
      expect(find.byType(AppLoadingDisplay), findsOneWidget);
    });

    testWidgets('can display an error state', (WidgetTester tester) async {
      when(() => mockProfileEditCubit.state)
          .thenReturn(ProfileEditState.error());
      when(() => mockProfileEditCubit.stream).thenAnswer(
        (_) =>
            Stream<ProfileEditState>.fromIterable([ProfileEditState.error()]),
      );

      await tester.pumpWidget(
        ProfileTestHelper.withLocalizationProvider(
          BlocProvider<ProfileEditCubit>(
            create: (context) => mockProfileEditCubit,
            child: ShaderRenderingScope(
              enabled: false,
              child: OnboardingWizardScreen(profileId: 'test_profile_id'),
            ),
          ),
        ),
      );
      expect(find.byType(AppErrorDisplay), findsOneWidget);
      // Error state must stay escapable even on first sign-in.
      expect(find.byType(CustomBackButton), findsOneWidget);
    });

    testWidgets('can display loaded state', (WidgetTester tester) async {
      await mockNetworkImages(() async {
        final Profile profile = Faker().createProfile();

        when(() => mockProfileEditCubit.state)
            .thenReturn(ProfileEditState.loaded(profile: profile));
        when(() => mockProfileEditCubit.stream).thenAnswer(
          (_) => Stream<ProfileEditState>.fromIterable([
            ProfileEditState.loaded(profile: profile),
          ]),
        );

        await tester.pumpWidget(
          ProfileTestHelper.withLocalizationProvider(
            MultiProvider(
              providers: [
                Provider<Services>.value(value: mockServices),
                BlocProvider<ProfileEditCubit>(
                  create: (context) => mockProfileEditCubit,
                ),
              ],
              child: ShaderRenderingScope(
                enabled: false,
                child: OnboardingWizardScreen(
                  profileId: 'test_profile_id',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('onboarding_wizard_intro_message')),
            findsOneWidget);
        expect(find.byType(ProfileBasicsFields), findsNothing);
        expect(find.byType(OnboardingWizardStepIndicator), findsOneWidget);
        final indicator = tester.widget<AnimatedSmoothIndicator>(
          find.byType(AnimatedSmoothIndicator),
        );
        expect(indicator.count, 3);
        expect(indicator.activeIndex, 0);
        expect(find.byType(AnimatedSwitcher), findsWidgets);
        expect(
          tester.getBottomLeft(find.byType(OnboardingWizardStepIndicator)).dy,
          lessThanOrEqualTo(tester.getTopLeft(find.byType(AppButton)).dy),
        );
        for (final step in ['intro', 'basics', 'location']) {
          expect(
            find.byKey(Key('onboarding_wizard_step_$step')),
            findsOneWidget,
          );
        }
        expect(find.text('ELLENŐRZÉS'), findsOneWidget);

        await tester.tap(find.byType(AppButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        expect(find.byKey(const Key('onboarding_wizard_intro_message')),
            findsOneWidget);
        expect(find.byType(ProfileBasicsFields), findsOneWidget);
        expect(
          tester.widget<AnimatedSmoothIndicator>(
            find.byType(AnimatedSmoothIndicator),
          ).activeIndex,
          1,
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProfileBasicsFields), findsOneWidget);
        expect(find.byType(ProfileLocationField), findsNothing);
        expect(find.byType(OnboardingWizardStepIndicator), findsOneWidget);
        final l10n = ProfileLocalizations.of(
          tester.element(find.byType(OnboardingWizardScreen)),
        );
        expect(find.text(l10n.profileWizardStepLabel(2, 3)), findsNothing);
        expect(find.text(l10n.profileBasicsTitle), findsOneWidget);
        expect(find.text(l10n.profileBasicsDescription), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
        expect(find.text('TOVÁBB'), findsOneWidget);
      });
    });

    testWidgets('indicator navigation preserves edits and requires saving basics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mockNetworkImages(() async {
        final profile = Faker().createProfile();
        void Function(Profile)? completeSave;
        void Function(Object?, StackTrace)? failSave;
        when(() => mockProfileEditCubit.state)
            .thenReturn(ProfileEditState.loaded(profile: profile));
        when(() => mockProfileEditCubit.stream).thenAnswer(
          (_) => Stream<ProfileEditState>.fromIterable([
            ProfileEditState.loaded(profile: profile),
          ]),
        );
        when(
          () => mockProfileEditCubit.updateProfile(
            profile: any(named: 'profile'),
            formData: any(named: 'formData'),
            onComplete: any(named: 'onComplete'),
            onError: any(named: 'onError'),
            completeProfile: any(named: 'completeProfile'),
          ),
        ).thenAnswer((invocation) {
          completeSave =
              invocation.namedArguments[#onComplete] as void Function(Profile);
          failSave = invocation.namedArguments[#onError]
              as void Function(Object?, StackTrace);
        });

        await tester.pumpWidget(
          ProfileTestHelper.withLocalizationProvider(
            Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (_) => MultiProvider(
                    providers: [
                      Provider<Services>.value(value: mockServices),
                      BlocProvider<ProfileEditCubit>(
                        create: (context) => mockProfileEditCubit,
                      ),
                    ],
                    child: ShaderRenderingScope(
                      enabled: false,
                      child: OnboardingWizardScreen(profileId: 'test_profile_id'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final intro = find.byKey(const Key('onboarding_wizard_step_intro'));
        final basics = find.byKey(const Key('onboarding_wizard_step_basics'));
        final location =
            find.byKey(const Key('onboarding_wizard_step_location'));
        await tester.tap(location);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('onboarding_wizard_intro_message')),
            findsOneWidget);
        expect(find.byType(ProfileBasicsFields), findsNothing);
        await tester.tap(basics);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileBasicsFields), findsOneWidget);
        expect(find.byType(ProfileLocationField), findsNothing);
        final l10n = ProfileLocalizations.of(
          tester.element(find.byType(OnboardingWizardScreen)),
        );
        final headlineStyle =
            tester.widget<Text>(find.text(l10n.profileBasicsTitle)).style;
        final descriptionStyle =
            tester.widget<Text>(find.text(l10n.profileBasicsDescription)).style;

        await tester.tap(intro);
        await tester.pump(const Duration(milliseconds: 20));
        await tester.tap(basics);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileBasicsFields), findsOneWidget);

        await tester.drag(
          find.byKey(const Key('default_screen_setup_custom_scroll_view')),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        final firstName = find.descendant(
          of: find.byKey(const Key('profile_edit_form_first_name_input')),
          matching: find.byType(EditableText),
        );
        expect(
          tester.getBottomLeft(firstName).dy,
          lessThan(
            tester.getTopLeft(find.byType(OnboardingWizardStepIndicator)).dy,
          ),
        );
        await tester.ensureVisible(firstName);
        await tester.enterText(firstName, '');
        tester.testTextInput.hide();
        await tester.tap(location);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileLocationField), findsNothing);
        expect(completeSave, isNull);

        await tester.enterText(firstName, 'Alice');
        tester.testTextInput.hide();
        final imageData = Uint8List.fromList([1, 2, 3]);
        tester.state<FormBuilderImagePickerState>(
          find.byKey(const Key('profile_edit_form_image_picker')),
        ).didChange(imageData);
        await tester.pump();
        await tester.tap(intro);
        await tester.pumpAndSettle();
        await tester.tap(basics);
        await tester.pumpAndSettle();
        expect(tester.widget<EditableText>(firstName).controller.text, 'Alice');
        expect(
          tester.state<FormBuilderImagePickerState>(
            find.byKey(const Key('profile_edit_form_image_picker')),
          ).value,
          imageData,
        );

        await tester.tap(location);
        await tester.pumpAndSettle();
        expect(completeSave, isNull);
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();
        expect(completeSave, isNotNull);
        final savedData = verify(
          () => mockProfileEditCubit.updateProfile(
            profile: profile,
            formData: captureAny(named: 'formData'),
            onComplete: any(named: 'onComplete'),
            onError: any(named: 'onError'),
            completeProfile: true,
          ),
        ).captured.single as Map<String, dynamic>;
        expect(savedData['firstName'], 'Alice');
        expect(savedData['imageData'], imageData);
        expect(find.byType(ProfileLocationField), findsNothing);
        await tester.tap(intro);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileBasicsFields), findsOneWidget);

        failSave!(Exception('save failed'), StackTrace.current);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileLocationField), findsNothing);
        completeSave!(profile);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileLocationField), findsOneWidget);
        expect(
          tester.widget<Text>(find.text(l10n.locationPitchTitle)).style,
          headlineStyle,
        );
        expect(
          tester.widget<Text>(find.text(l10n.locationPitchBody)).style,
          descriptionStyle,
        );
        final coreL10n = CoreLocalizations.of(
          tester.element(find.byType(OnboardingWizardScreen)),
        );
        expect(find.text(coreL10n.locationInputRationaleTitle), findsNothing);
        const city = Location(
          name: 'Budapest',
          latLng: LatLng(latitude: 47.5, longitude: 19.0),
          geoHash: 'u2m',
        );
        final cityField =
            find.byKey(const Key('profile_edit_form_location_input'));
        tester.state<FormBuilderCitySelectorState>(cityField).didChange(city);
        await tester.pump();
        expect(find.byType(AppMap), findsOneWidget);
        await tester.tap(intro);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('onboarding_wizard_intro_message')),
            findsOneWidget);
        await tester.tap(location);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileLocationField), findsOneWidget);
        expect(tester.state<FormBuilderCitySelectorState>(cityField).value, city);
        await tester.tap(basics);
        await tester.pumpAndSettle();
        await tester.enterText(firstName, 'Bob');
        tester.testTextInput.hide();
        await tester.tap(location);
        await tester.pumpAndSettle();
        expect(find.byType(ProfileBasicsFields), findsOneWidget);
        await tester.tap(intro);
        await tester.pumpAndSettle();
        await tester.tap(location);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('onboarding_wizard_intro_message')),
            findsOneWidget);
        await tester.tap(basics);
        await tester.pumpAndSettle();
        expect(tester.widget<EditableText>(firstName).controller.text, 'Bob');
      });
    });

    testWidgets('can handle form submission', (WidgetTester tester) async {
      await mockNetworkImages(() async {
        final Profile profile = Faker().createProfile();

        when(() => mockProfileEditCubit.state)
            .thenReturn(ProfileEditState.loaded(profile: profile));
        when(() => mockProfileEditCubit.stream).thenAnswer(
          (_) => Stream<ProfileEditState>.fromIterable([
            ProfileEditState.loaded(profile: profile),
          ]),
        );

        await tester.pumpWidget(
          ProfileTestHelper.withLocalizationProvider(
            MultiProvider(
              providers: [
                Provider<Services>.value(value: mockServices),
                BlocProvider<ProfileEditCubit>(
                  create: (context) => mockProfileEditCubit,
                ),
              ],
              child: ShaderRenderingScope(
                enabled: false,
                child: OnboardingWizardScreen(profileId: 'test_profile_id'),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AppButton)); // intro
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        verify(
          () => mockProfileEditCubit.updateProfile(
            profile: profile,
            formData: any(named: 'formData'),
            onComplete: any(
              named: 'onComplete',
              that: isA<Function(Profile)>(),
            ),
            onError: any(
              named: 'onError',
              that: isA<Function(Object?, StackTrace)>(),
            ),
            completeProfile: true,
          ),
        ).called(1);
      });
    });

    testWidgets('moves to the optional location step after basics are saved',
        (WidgetTester tester) async {
      await mockNetworkImages(() async {
        final Profile profile = Faker().createProfile();

        when(() => mockProfileEditCubit.state)
            .thenReturn(ProfileEditState.loaded(profile: profile));
        when(() => mockProfileEditCubit.stream).thenAnswer(
          (_) => Stream<ProfileEditState>.fromIterable([
            ProfileEditState.loaded(profile: profile),
          ]),
        );
        when(
          () => mockProfileEditCubit.updateProfile(
            profile: any(named: 'profile'),
            formData: any(named: 'formData'),
            onComplete: any(named: 'onComplete'),
            onError: any(named: 'onError'),
            completeProfile: any(named: 'completeProfile'),
          ),
        ).thenAnswer((invocation) {
          final onComplete = invocation.namedArguments[#onComplete]
              as void Function(Profile);
          onComplete(profile);
        });
        when(() => mockServices.analyticsService)
            .thenReturn(MockAnalyticsService());
        when(() => mockHapticsService.success()).thenReturn(null);
        when(() => mockHapticsService.tap()).thenReturn(null);

        await tester.pumpWidget(
          ProfileTestHelper.withLocalizationProvider(
            MultiProvider(
              providers: [
                Provider<Services>.value(value: mockServices),
                BlocProvider<ProfileEditCubit>(
                  create: (context) => mockProfileEditCubit,
                ),
              ],
              child: ShaderRenderingScope(
                enabled: false,
                child: OnboardingWizardScreen(profileId: 'test_profile_id'),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AppButton)); // intro
        await tester.pumpAndSettle();
        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(find.byType(ProfileLocationField), findsOneWidget);
        expect(find.text('BEFEJEZÉS'), findsOneWidget);
      });
    });

    for (final intent in OnboardingIntent.values) {
      testWidgets('shows a distinct intro message for ${intent.name}',
          (WidgetTester tester) async {
        await mockNetworkImages(() async {
          final Profile profile = Faker().createProfile();
          when(() => mockProfileEditCubit.state)
              .thenReturn(ProfileEditState.loaded(profile: profile));
          when(() => mockProfileEditCubit.stream).thenAnswer(
            (_) => Stream<ProfileEditState>.fromIterable([
              ProfileEditState.loaded(profile: profile),
            ]),
          );

          await tester.pumpWidget(
            ProfileTestHelper.withLocalizationProvider(
              MultiProvider(
                providers: [
                  Provider<Services>.value(value: mockServices),
                  BlocProvider<ProfileEditCubit>(
                    create: (context) => mockProfileEditCubit,
                  ),
                ],
                child: ShaderRenderingScope(
                  enabled: false,
                  child: OnboardingWizardScreen(
                    profileId: 'test_profile_id',
                    intent: intent,
                  ),
                ),
              ),
              locale: intent == OnboardingIntent.firstSignIn
                  ? const Locale('en')
                  : const Locale('hu'),
            ),
          );
          await tester.pumpAndSettle();

          final l10n = ProfileLocalizations.of(
            tester.element(find.byType(OnboardingWizardScreen)),
          );
          final expected = switch (intent) {
            OnboardingIntent.firstSignIn => l10n.onboardingWelcomeDescription,
            OnboardingIntent.completeProfile => l10n.profileWizardDescription,
          };
          expect(find.text(expected), findsOneWidget);
          expect(
            find.text(intent == OnboardingIntent.firstSignIn
                ? 'CHECK'
                : 'ELLENŐRZÉS'),
            findsOneWidget,
          );
          // Only the profile-button entry can be dismissed.
          expect(
            find.byType(CustomBackButton),
            intent == OnboardingIntent.completeProfile
                ? findsOneWidget
                : findsNothing,
          );
          expect(find.byType(CustomAppBar), 
            intent == OnboardingIntent.completeProfile
                ? findsOneWidget
                : findsNothing,
          );
        });
      });
    }
  });
}
