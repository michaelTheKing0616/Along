import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/app.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/observability/sentry_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  final config = AppConfig.fromEnvironment();

  Future<void> runAlongApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Geist/Inter load beside bootstrap, so first frame has the real type.
    final fonts = AlongFonts.ensureLoaded();
    final container = await bootstrapApp(configOverride: config);
    await fonts;
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const AlongDriverApp(),
      ),
    );
  }

  if (config.hasSentry) {
    await SentryFlutter.init(
      (options) {
        options.dsn = config.sentryDsn;
        options.beforeSend = scrubPii;
        options.tracesSampleRate = config.sentryTracesSampleRate;
      },
      appRunner: runAlongApp,
    );
  } else {
    await runAlongApp();
  }
}
