import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/app_router.dart';

class AlongRiderApp extends ConsumerWidget {
  const AlongRiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Along',
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

/// Initializes Supabase and provider overrides for the app shell.
Future<ProviderContainer> bootstrapApp({AppConfig? configOverride}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = configOverride ?? AppConfig.fromEnvironment();
  final supabase = await createAlongSupabase(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  return ProviderContainer(
    overrides: buildProviderOverrides(
      config: config,
      supabase: supabase,
    ),
  );
}
