/// Cold-start timing harness (doc 01 §7, doc 07 §13).
///
/// Measurement method on reference device (Redmi A2+ / Tecno Spark 8C, 2 GB RAM):
/// 1. Call [markProcessStart] as the first line of `main()`.
/// 2. Call [markBindingReady] after `WidgetsFlutterBinding.ensureInitialized()`.
/// 3. Call [markBootstrapComplete] when Supabase + Drift init finishes, before `runApp`.
/// 4. Report [coldStartMs] to Sentry as `app.cold_start_ms` span attribute.
///
/// PASS when [coldStartMs] ≤ 2500 on reference hardware. CI validates math only.
class AppStartupMetrics {
  AppStartupMetrics._();

  static final AppStartupMetrics instance = AppStartupMetrics._();

  DateTime? _processStart;
  DateTime? _bindingReady;
  DateTime? _bootstrapComplete;

  /// Marks app process entry (first line of `main`).
  void markProcessStart() {
    _processStart ??= DateTime.now();
  }

  /// Marks Flutter binding initialization complete.
  void markBindingReady() {
    _bindingReady ??= DateTime.now();
  }

  /// Marks end of async bootstrap (Supabase, Drift, providers) before first frame.
  void markBootstrapComplete() {
    _bootstrapComplete ??= DateTime.now();
  }

  /// Resets markers (tests only).
  void resetForTest() {
    _processStart = null;
    _bindingReady = null;
    _bootstrapComplete = null;
  }

  /// Wall-clock ms from process start to bootstrap complete.
  int? get coldStartMs {
    if (_processStart == null || _bootstrapComplete == null) return null;
    return _bootstrapComplete!.difference(_processStart!).inMilliseconds;
  }

  int? get bindingInitMs {
    if (_processStart == null || _bindingReady == null) return null;
    return _bindingReady!.difference(_processStart!).inMilliseconds;
  }

  int? get bootstrapAsyncMs {
    if (_bindingReady == null || _bootstrapComplete == null) return null;
    return _bootstrapComplete!.difference(_bindingReady!).inMilliseconds;
  }

  /// Budget from doc 01 §7 (rider APK cold start on 2 GB / Android 10).
  static const int coldStartBudgetMs = 2500;

  bool get passesColdStartBudget =>
      coldStartMs != null && coldStartMs! <= coldStartBudgetMs;

  Map<String, int?> toReport() => {
        'cold_start_ms': coldStartMs,
        'binding_init_ms': bindingInitMs,
        'bootstrap_async_ms': bootstrapAsyncMs,
      };
}
