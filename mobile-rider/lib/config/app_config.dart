import 'package:along_map/along_map.dart';

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
  });

  final String flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String? sentryDsn;
  final String? tilesBaseUrl;
  final int otpResendCooldownS;
  final int otpRateLimitRetryS;
  final double sentryTracesSampleRate;

  bool get hasSentry => sentryDsn != null && sentryDsn!.trim().isNotEmpty;

  /// False when the APK was built without `--dart-define-from-file` staging/prod.
  bool get hasBackend {
    final url = supabaseUrl.trim();
    final key = supabaseAnonKey.trim();
    if (url.isEmpty || key.isEmpty) return false;
    if (url.contains('placeholder')) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// True when the build points at a tiles host that exists.
  /// Empty values and the retired along.ng tile domains are not reachable.
  bool get hasTiles => AlongStyleLoader.isReachableTilesBase(tilesBaseUrl);

  /// Retained for callers that still opt into MapLibre demotiles.
  /// Home and trip maps use OpenFreeMap instead of that world demo.
  bool get allowsDemoMapFallback => flavor != 'prod';

  static AppConfig fromEnvironment() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const sentryDsn = String.fromEnvironment('SENTRY_DSN');
    // Mobile env files use TILES_BASE_URL; root env/staging.json uses TILES_BASE
    // (mapped by scripts/wire_staging.sh). Accept both so a mis-keyed define
    // still wires tiles.
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

    final resolvedTiles = tilesBaseUrl.isNotEmpty
        ? tilesBaseUrl
        : (tilesBaseAlias.isNotEmpty ? tilesBaseAlias : null);

    return AppConfig(
      flavor: flavor,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      sentryDsn: sentryDsn.isEmpty ? null : sentryDsn,
      tilesBaseUrl: resolvedTiles,
      otpResendCooldownS: otpResendCooldownS,
      otpRateLimitRetryS: otpRateLimitRetryS,
      sentryTracesSampleRate: double.tryParse(sentryTracesSampleRateRaw) ?? 0.2,
    );
  }
}
