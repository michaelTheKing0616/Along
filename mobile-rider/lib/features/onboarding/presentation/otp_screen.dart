import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-03 OTP verification — auto-submit at 6 digits (doc 06 R-03).
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (code.length != 6) return;
    final success = await ref
        .read(onboardingControllerProvider.notifier)
        .verifyOtp(code);
    if (success && mounted) {
      context.go(AppRoutes.name);
    }
  }

  String? _localizedError(AppLocalizations l10n, String? key) {
    return switch (key) {
      'wrong_otp' => l10n.errorWrongOtp,
      'expired_otp' => l10n.errorExpiredOtp,
      'rate_limited' => l10n.errorRateLimited(60),
      'generic' => l10n.errorGeneric,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final theme = Theme.of(context);
    final displayPhone = state.displayPhone ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AlongColors.surface0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AlongColors.ink900),
          onPressed: () {
            ref.read(onboardingControllerProvider.notifier).clearPhone();
            context.go(AppRoutes.phone);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.otpTitle(displayPhone),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AlongSpace.s24),
              OtpField(
                key: const Key('otp_field'),
                controller: _controller,
                errorText: _localizedError(l10n, state.errorMessage),
                onChanged: (value) {
                  if (value.length == 6 && !state.isSubmitting) {
                    _verify(value);
                  }
                },
              ),
              const SizedBox(height: AlongSpace.s16),
              if (state.resendSecondsRemaining > 0)
                Text(
                  l10n.resendCountdown(state.resendSecondsRemaining),
                  style: theme.textTheme.bodySmall,
                )
              else
                TextButton(
                  key: const Key('otp_resend_button'),
                  onPressed: state.isSubmitting
                      ? null
                      : () => ref
                          .read(onboardingControllerProvider.notifier)
                          .resendOtp(),
                  child: Text(l10n.resendCode),
                ),
              TextButton(
                key: const Key('otp_wrong_number_button'),
                onPressed: () {
                  ref.read(onboardingControllerProvider.notifier).clearPhone();
                  context.go(AppRoutes.phone);
                },
                child: Text(l10n.wrongNumber),
              ),
              if (state.isSubmitting) ...[
                const SizedBox(height: AlongSpace.s16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
