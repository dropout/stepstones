import 'package:core/core.dart';
import 'package:faker/faker.dart';
import 'package:get_it/get_it.dart';
import 'package:profile/l10n/profile_localizations.dart';
import 'package:profile/src/data/datasource/faker_profile_extension.dart';
import 'package:profile/src/presentation/view/profile_basics_fields.dart';
import 'package:profile/src/presentation/view/profile_location_field.dart';
import 'package:profile/src/presentation/view/wizard/onboarding_wizard_step_indicator.dart';
import 'package:profile/src/presentation/view/screen/onboarding_wizard_screen.dart';

import 'package:profile/src/presentation/viewmodel/profile_edit_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart' show Key;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:profile/src/public/model/profile.dart';
import 'package:provider/provider.dart';

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
                child: OnboardingWizardScreen(profileId: 'test_profile_id'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('onboarding_wizard_intro_message')),
            findsOneWidget);
        expect(find.byType(ProfileBasicsFields), findsNothing);
        expect(find.byType(OnboardingWizardStepIndicator), findsNothing);
        expect(find.text('TOVÁBB'), findsOneWidget);

        await tester.tap(find.byType(AppButton));
        await tester.pumpAndSettle();

        expect(find.byType(ProfileBasicsFields), findsOneWidget);
        expect(find.byType(ProfileLocationField), findsNothing);
        expect(find.byType(OnboardingWizardStepIndicator), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
        expect(find.text('TOVÁBB'), findsOneWidget);
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
        expect(find.text('MOST NEM', skipOffstage: false), findsOneWidget);
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
