import 'package:along_design/along_design.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/onboarding/presentation/auth_shared.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-02 Phone entry. The value story sits above the field, so first run
/// is one screen and one tap to the code (doc 06 R-02).
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen>
    with AuthOfflineAware {
  final _controller = TextEditingController();
  late final _wait = RetryClock(() {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeWait());
  }

  void _resumeWait() {
    final state = ref.read(onboardingControllerProvider);
    if (state.errorMessage == 'rate_limited' && _wait.remaining == 0) {
      _wait.start(
        state.rateLimitRetrySeconds ??
            ref.read(appConfigProvider).otpRateLimitRetryS,
      );
    }
  }

  int _lastLength = 0;

  // Typing, paste and autofill all land here, so the button follows them.
  void _onText() {
    final length = _digits.length;
    if (length == _lastLength) return;
    _lastLength = length;
    ref.read(onboardingControllerProvider.notifier).clearError();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _wait.dispose();
    _controller.dispose();
    super.dispose();
  }

  String get _digits => _controller.text.replaceAll(' ', '');

  Future<void> _submit() async {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final success = await notifier.requestOtp(_digits);
    if (!mounted) return;
    if (success) {
      FocusManager.instance.primaryFocus?.unfocus();
      context.go(AppRoutes.otp);
      return;
    }
    _wait.remaining = 0;
    _resumeWait();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final palette = AlongPalette.of(context);
    final offline = watchOffline();
    final phonePrefix =
        ref.watch(phoneFormatterProvider).valueOrNull?.phonePrefix ?? '+234';
    final waiting = state.errorMessage == 'rate_limited' && _wait.remaining > 0;
    final height = MediaQuery.sizeOf(context).height;

    final Widget? notice = offline
        ? AlongAuthNotice(
            key: const Key('auth_notice_offline'),
            tone: AlongAuthNoticeTone.offline,
            message: l10n.authOffline,
            actionLabel: l10n.connRetry,
            onAction: retryConnection,
          )
        : switch (state.errorMessage) {
            'rate_limited' when waiting => AlongAuthNotice(
              key: const Key('auth_notice_rate_limited'),
              tone: AlongAuthNoticeTone.wait,
              message: l10n.errorRateLimited(_wait.remaining),
            ),
            'not_configured' => AlongAuthNotice(
              tone: AlongAuthNoticeTone.error,
              message: l10n.errorAuthNotConfigured,
            ),
            'generic' => AlongAuthNotice(
              key: const Key('auth_notice_error'),
              tone: AlongAuthNoticeTone.error,
              message: l10n.errorGeneric,
              actionLabel: l10n.connRetry,
              onAction: _submit,
            ),
            _ => null,
          };

    final link = TextStyle(
      decoration: TextDecoration.underline,
      color: palette.ink,
    );

    return AlongAuthScaffold(
      hero: AlongValueStory(
        height: (height * (notice == null ? 0.4 : 0.32)).clamp(270.0, 380.0),
        slides: [
          AlongStorySlide(headline: l10n.authStory1H, body: l10n.authStory1B),
          AlongStorySlide(headline: l10n.authStory2H, body: l10n.authStory2B),
          AlongStorySlide(headline: l10n.authStory3H, body: l10n.authStory3B),
        ],
      ),
      title: l10n.authYourNumber,
      subtitle: l10n.phoneEntrySubtitle,
      notice: notice,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AlongPhoneInput(
            fieldKey: const Key('phone_field'),
            controller: _controller,
            dialCode: phonePrefix,
            autofocus: false,
            errorText: state.errorMessage == 'invalid_phone'
                ? l10n.errorInvalidPhone
                : null,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: AlongType.caption(palette),
              children: [
                TextSpan(text: l10n.legalPrefix),
                TextSpan(
                  text: l10n.termsLink,
                  style: link,
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                TextSpan(text: l10n.legalMiddle),
                TextSpan(
                  text: l10n.privacyLink,
                  style: link,
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: AlongButton(
        key: const Key('phone_continue_button'),
        label: l10n.authSendCode,
        onPressed:
            state.isSubmitting || offline || waiting || _digits.length < 10
            ? null
            : _submit,
        visualState: state.isSubmitting
            ? AlongButtonVisualState.loading
            : AlongButtonVisualState.normal,
      ),
    );
  }
}
