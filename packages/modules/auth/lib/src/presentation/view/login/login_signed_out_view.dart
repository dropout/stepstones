import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core/core.dart';
import 'package:auth/l10n/auth_localizations.dart';
import 'package:auth/src/presentation/view/login/login_headline_text_effect.dart';

class LoginSignedOutView extends StatelessWidget {
  const new({super.key});

  static const letterDuration = Durations.medium3;

  void _onLoginWithGoogleTap(BuildContext context) {
    context.read<AuthStateCubit>().signinWithGoogle();
    context.logEvent(name: 'login_with_google_button_pressed');
    context.hapticsTap();
  }

  // void _onLoginWithAppleTap(BuildContext context) {
  //   context.read<AuthStateCubit>().signinWithApple();
  //   context.logEvent(name: 'login_with_apple_button_pressed');
  //   context.hapticsTap();
  // }

  void _onLoginWithEmailAndPasswordTap(BuildContext context) {
    context.services.authNavigator.navigateToLoginWithEmailAndPassword();
    context.logEvent(name: 'login_with_email_and_password_button_pressed');
    context.hapticsTap();
  }

  void _onTermsTap(BuildContext context) {
    // TODO: Replace with actual terms of service URL
    context.services.urlLauncher.launchInAppWebView('https://google.com');
    context.logEvent(name: 'view_tou_pressed');
    context.hapticsTap();
  }

  void _onPrivacyTap(BuildContext context) {
    // TODO: Replace with actual privacy policy URL
    context.services.urlLauncher.launchInAppWebView('https://google.com');
    context.logEvent(name: 'view_privacy_policy_pressed');
    context.hapticsTap();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        // Old paper layer
        ParchmentBackground(),

        // Particle effects with '?' layer
        // LoginBackgroundEffect(),

        // Column for content
        SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Animated headline text
                      Expanded(
                        child: _buildHeadline(context)                        
                      ),

                      // Why sign in? section
                      _buildSignupBenefits(context),

                      // Actions
                      _buildActions(context),
                      Gap.large(),

                      // Legal text
                      _buildLegalText(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeadline(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.headlineLarge!.copyWith(
      fontWeight: FontWeight.w900,
      fontSize: 80,
      color: Colors.black,
      height: 1.0,
      // fontFamily: DesignSpec.condensedFontFamilyName,
    );

    return SafeArea(
      bottom: false,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            LoginHeadlineTextEffect(
              text: AuthLocalizations.of(context).loginHeadline1,
              textStyle: textStyle,
              duration: letterDuration * 3,
            ),
            LoginHeadlineTextEffect(
              text: AuthLocalizations.of(context).loginHeadline2,
              textStyle: textStyle,
              duration: letterDuration * 3,
              initialDelay: Durations.medium1,
            ),
            LoginHeadlineTextEffect(
              text: AuthLocalizations.of(context).loginHeadline3,
              textStyle: textStyle,
              duration: letterDuration * 4,
              initialDelay: Durations.long2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupBenefits(BuildContext context) {
    final l10n = AuthLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpec.spacingMd),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // color: AppColors.appWhite.withValues(alpha: 0.72),
          // border: Border.all(color: Colors.black, width: 1.5),
          // borderRadius: BorderRadius.circular(DesignSpec.borderRadiusSm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: DesignSpec.padding2Xl,
            horizontal: DesignSpec.paddingLg,
          ),
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            children: [
              Text(
                l10n.loginSignupBenefitsTitle,
                textAlign: .center,
                key: const Key('login_signup_benefits_title'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Gap.small(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SignupBenefit(text: l10n.loginSignupBenefitChanting),
                  Gap.xs(),
                  SignupBenefit(text: l10n.loginSignupBenefitStats),
                  Gap.xs(),
                  SignupBenefit(text: l10n.loginSignupBenefitPresence),
                ],
              ),
            ],
          ),
        ),
      ),
    ).reveal(2);
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignSpec.spacingMd),
      child: Column(
        children: [
          AppButton(
            key: const Key('login_with_google_button'),
            text: AuthLocalizations.of(context).loginSigninGoogle,
            bColor: Colors.black,
            fColor: AppColors.appWhite,
            onTap: () => _onLoginWithGoogleTap(context),
          ).reveal(3),
          Gap.medium(),
          AppButton(
            key: const Key('login_with_apple_button'),
            text: AuthLocalizations.of(context).loginSigninApple,
            bColor: Colors.black,
            fColor: AppColors.appWhite,
            // onTap: () => _onLoginWithAppleTap(context),
          ).reveal(4),
          Gap.medium(),
          buildEmailAndPasswordButton(context).reveal(5),
        ],
      ),
    );
  }

  /// Only build the email and password button if the
  /// the enviroment variable `ENABLE_EMAIL_PASSWORD_SIGNIN` is set to true.
  Widget buildEmailAndPasswordButton(BuildContext context) {
    final bool enableEmailPasswordSigning = bool.fromEnvironment('ENABLE_EMAIL_PASSWORD_SIGNIN');
    if (!enableEmailPasswordSigning) return const SizedBox.shrink();

    return AppButton(
      text: AuthLocalizations.of(context).loginSigninEmailPassword,
      bColor: Colors.black,
      fColor: Colors.white,
      onTap: () => _onLoginWithEmailAndPasswordTap(context),
    );
  }

  Widget _buildLegalText(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: DesignSpec.spacingMd, right: DesignSpec.spacingMd, bottom: DesignSpec.spacingMd),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(height: 1.5),
          children: [
            TextSpan(text: AuthLocalizations.of(context).loginLegalPart1),
            TextSpan(
              text: AuthLocalizations.of(context).loginLegalPart2,
              style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()..onTap = () => _onTermsTap(context),
            ),
            TextSpan(text: AuthLocalizations.of(context).loginLegalPart3),
            TextSpan(
              text: AuthLocalizations.of(context).loginLegalPart4,
              style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()..onTap = () => _onPrivacyTap(context),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    ).reveal(6);
  }
}

class const SignupBenefit({
  required final String text,
  final IconData? icon,
  super.key,
}) extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignSpec.spacingXs),
      child: Row(
        mainAxisAlignment: .center,
        children: [
          if (icon != null) Icon(icon, color: Colors.black, size: 24),
          if (icon != null) Gap.xs(),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
