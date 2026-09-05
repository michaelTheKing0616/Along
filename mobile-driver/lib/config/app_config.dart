/// Flavour and runtime configuration from `--dart-define-from-file`.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.sentryDsn,
    this.tilesBaseUrl,
    this.otpResendCooldownS = 30,
    this.otpRateLimitRetryS = 60,
    this.sentryTracesSampleRate = 0.2,
    this.batteryGuardPercent = 15,
  });

  final String flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String? sentryDsn;
  final String? tilesBaseUrl;
  final int otpResendCooldownS;
  final int otpRateLimitRetryS;
  final double sentryTracesSampleRate;
  final int batteryGuardPercent;

  bool get hasSentry =>
      sentryDsn != null && sentryDsn!.trim().isNotEmpty;

  static AppConfig fromEnvironment() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const sentryDsn = String.fromEnvironment('SENTRY_DSN');
    const tilesBaseUrl = String.fromEnvironment('TILES_BASE_URL');
    const otpResendCooldownS = int.fromEnvironment(
      'OTP_RESEND_COOLDOWN_S',
      defaultValue: 30,
    );
    const otpRateLimitRetryS = int.fromEnvironment(
      'OTP_RATE_LIMIT_RETRY_S',
      defaultValue: 60,
    );
    const sentryTracesSampleRateRaw = String.fromEnvironment(
      'SENTRY_TRACES_SAMPLE_RATE',
      defaultValue: '0.2',
    );
    const batteryGuardPercent = int.fromEnvironment(
      'BATTERY_GUARD_PERCENT',
      defaultValue: 15,
    );

    return AppConfig(
      flavor: flavor,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      sentryDsn: sentryDsn.isEmpty ? null : sentryDsn,
      tilesBaseUrl: tilesBaseUrl.isEmpty ? null : tilesBaseUrl,
      otpResendCooldownS: otpResendCooldownS,
      otpRateLimitRetryS: otpRateLimitRetryS,
      sentryTracesSampleRate:
          double.tryParse(sentryTracesSampleRateRaw) ?? 0.2,
      batteryGuardPercent: batteryGuardPercent,
    );
  }
}
