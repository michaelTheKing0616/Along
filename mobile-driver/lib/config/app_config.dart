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

  bool get hasBackend {
    final url = supabaseUrl.trim();
    final key = supabaseAnonKey.trim();
    if (url.isEmpty || key.isEmpty) return false;
    if (url.contains('placeholder')) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// True when a real Along tiles CDN base was wired into the build.
  bool get hasTiles {
    final tiles = tilesBaseUrl?.trim() ?? '';
    return tiles.isNotEmpty;
  }

  /// Non-prod builds may fall back to MapLibre demotiles when [hasTiles] is false.
  bool get allowsDemoMapFallback => flavor != 'prod';

  static AppConfig fromEnvironment() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const sentryDsn = String.fromEnvironment('SENTRY_DSN');
    const tilesBaseUrl = String.fromEnvironment('TILES_BASE_URL');
    const tilesBaseAlias = String.fromEnvironment('TILES_BASE');
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
      tilesBaseUrl: tilesBaseUrl.isNotEmpty
          ? tilesBaseUrl
          : (tilesBaseAlias.isNotEmpty ? tilesBaseAlias : null),
      otpResendCooldownS: otpResendCooldownS,
      otpRateLimitRetryS: otpRateLimitRetryS,
      sentryTracesSampleRate:
          double.tryParse(sentryTracesSampleRateRaw) ?? 0.2,
      batteryGuardPercent: batteryGuardPercent,
    );
  }
}
