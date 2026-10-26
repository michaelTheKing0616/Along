import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/app.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/observability/sentry_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  AppStartupMetrics.instance.markProcessStart();
  final config = AppConfig.fromEnvironment();

  Future<void> runAlongApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Geist registers in parallel with bootstrap, so no extra startup wait.
    final fonts = AlongFonts.ensureLoaded();
    final container = await bootstrapApp(configOverride: config);
    await fonts;
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const AlongRiderApp(),
      ),
    );
  }

  if (config.hasSentry) {
    await SentryFlutter.init((options) {
      options.dsn = config.sentryDsn;
      options.beforeSend = scrubPii;
      options.tracesSampleRate = config.sentryTracesSampleRate;
    }, appRunner: runAlongApp);
  } else {
    await runAlongApp();
  }
}
