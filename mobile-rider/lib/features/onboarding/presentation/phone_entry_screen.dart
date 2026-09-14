import 'package:along_design/along_design.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-02 Phone entry — OTP request (doc 06 R-02).
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final success = await ref
        .read(onboardingControllerProvider.notifier)
        .requestOtp(_controller.text.trim());
    if (!mounted) return;
    if (success) {
      context.go(AppRoutes.otp);
      return;
    }
    final message = _localizedError(
      AppLocalizations.of(context),
      ref.read(onboardingControllerProvider),
    );
    if (message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _localizedError(AppLocalizations l10n, OnboardingState state) {
    final config = ref.read(appConfigProvider);
    return switch (state.errorMessage) {
      null => null,
      'invalid_phone' => l10n.errorInvalidPhone,
      'not_configured' => l10n.errorAuthNotConfigured,
      'rate_limited' => l10n.errorRateLimited(
          state.rateLimitRetrySeconds ?? config.otpRateLimitRetryS,
        ),
      _ => l10n.errorGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final theme = Theme.of(context);
    final phonePrefix =
        ref.watch(phoneFormatterProvider).valueOrNull?.phonePrefix ?? '+234';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AlongSpace.s24,
            AlongSpace.s16,
            AlongSpace.s24,
            AlongSpace.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: 'along_logo_small',
                        child: SvgPicture.asset(
                          alongLogoBlackSvg,
                          package: 'along_design',
                          width: 96,
                        ),
                      ),
                      const SizedBox(height: AlongSpace.s32),
                      Text(
                        l10n.phoneEntryTitle,
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(height: AlongSpace.s8),
                      Text(
                        l10n.phoneEntrySubtitle,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AlongSpace.s24),
                      PhoneField(
                        controller: _controller,
                        countryCode: phonePrefix,
                        errorText: _localizedError(l10n, state),
                        onChanged: (_) {
                          ref
                              .read(onboardingControllerProvider.notifier)
                              .clearError();
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AlongSpace.s16),
                      Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodySmall,
                          children: [
                            TextSpan(text: l10n.legalPrefix),
                            TextSpan(
                              text: l10n.termsLink,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: AlongColors.ink900,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {},
                            ),
                            TextSpan(text: l10n.legalMiddle),
                            TextSpan(
                              text: l10n.privacyLink,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: AlongColors.ink900,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AlongButton(
                key: const Key('phone_continue_button'),
                label: l10n.continueButton,
                onPressed: state.isSubmitting ? null : _submit,
                visualState: state.isSubmitting
                    ? AlongButtonVisualState.loading
                    : AlongButtonVisualState.normal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
