import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/onboarding/presentation/auth_shared.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-03 Code. Fills from the text message and checks itself at six
/// digits, no button (doc 06 R-03).
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> with AuthOfflineAware {
  final _controller = TextEditingController();
  late final _wait = RetryClock(() {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeWait();
      _tryStagingOtp();
    });
  }

  Future<void> _tryStagingOtp() async {
    final code = await ref
        .read(onboardingControllerProvider.notifier)
        .peekStagingOtp();
    if (!mounted || code == null || code.length != 6) return;
    _controller.text = code;
    await _verify(code);
  }

  @override
  void dispose() {
    _wait.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (code.length != 6) return;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    if (ref.read(onboardingControllerProvider).isSubmitting) return;
    final success = await notifier.verifyOtp(code);
    if (!mounted) return;
    if (success) {
      context.go(AppRoutes.name);
      return;
    }
    _controller.clear();
    _afterError();
  }

  Future<void> _resend() async {
    _controller.clear();
    await ref.read(onboardingControllerProvider.notifier).resendOtp();
    if (mounted) _afterError();
  }

  void _afterError() {
    _wait.remaining = 0;
    _resumeWait();
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

  void _changeNumber() {
    ref.read(onboardingControllerProvider.notifier).clearPhone();
    context.go(AppRoutes.phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final offline = watchOffline();
    final formatter = ref.watch(phoneFormatterProvider).valueOrNull;
    final displayPhone = formatter == null
        ? (state.phoneE164 ?? '')
        : (state.displayPhoneFor(formatter) ?? '');
    final waiting = state.errorMessage == 'rate_limited' && _wait.remaining > 0;

    final fieldError = switch (state.errorMessage) {
      'wrong_otp' => l10n.errorWrongOtp,
      'expired_otp' => l10n.errorExpiredOtp,
      _ => null,
    };
    final Widget? notice = offline
        ? AlongAuthNotice(
            key: const Key('auth_notice_offline'),
            tone: AlongAuthNoticeTone.offline,
            message: l10n.authOffline,
            actionLabel: l10n.connRetry,
            onAction: retryConnection,
          )
        : waiting
        ? AlongAuthNotice(
            key: const Key('auth_notice_rate_limited'),
            tone: AlongAuthNoticeTone.wait,
            message: l10n.errorRateLimited(_wait.remaining),
          )
        : state.errorMessage == 'generic'
        ? AlongAuthNotice(
            key: const Key('auth_notice_error'),
            tone: AlongAuthNoticeTone.error,
            message: l10n.errorGeneric,
          )
        : null;

    return AlongAuthScaffold(
      onBack: _changeNumber,
      backLabel: l10n.authBack,
      title: l10n.otpCheckTitle,
      subtitle: l10n.otpTitle(displayPhone.replaceAll(' ', '\u00A0')),
      notice: notice,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AlongCodeInput(
            key: const Key('otp_field'),
            controller: _controller,
            errorText: fieldError,
            checking: state.isSubmitting,
            checkingLabel: l10n.otpChecking,
            autofocus: !offline,
            onChanged: (_) {
              if (fieldError != null) {
                ref.read(onboardingControllerProvider.notifier).clearError();
              }
            },
            onCompleted: offline || waiting ? null : _verify,
          ),
          if (fieldError == null && !state.isSubmitting) ...[
            const SizedBox(height: 8),
            Text(
              l10n.otpAutofillHint,
              style: AlongType.caption(AlongPalette.of(context)),
            ),
          ],
        ],
      ),
      bottom: AlongResendRow(
        prompt: l10n.otpDidntGet,
        resendKey: const Key('otp_resend_button'),
        changeKey: const Key('otp_wrong_number_button'),
        enabled: !waiting && !offline && !state.isSubmitting,
        secondsRemaining: waiting ? 0 : state.resendSecondsRemaining,
        countdownLabel: (_) =>
            l10n.resendCountdown(state.resendSecondsRemaining),
        resendLabel: l10n.resendCode,
        changeLabel: l10n.wrongNumber,
        onResend: _resend,
        onChange: _changeNumber,
      ),
    );
  }
}
