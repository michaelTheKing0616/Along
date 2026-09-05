import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:along_location/along_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/config/app_config.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/app_router.dart';

class AlongDriverApp extends ConsumerWidget {
  const AlongDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Along Driver',
      theme: alongTheme(),
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

Future<ProviderContainer> bootstrapApp({AppConfig? configOverride}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = configOverride ?? AppConfig.fromEnvironment();
  final supabase = await createAlongSupabase(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  return ProviderContainer(
    overrides: [
      ...buildProviderOverrides(
        config: config,
        supabase: supabase,
        database: await AlongDatabase.open(fileName: 'driver.db'),
      ),
      driverForegroundNotifierProvider.overrideWithValue(
        FlutterForegroundDriverNotifier(),
      ),
    ],
  );
}
