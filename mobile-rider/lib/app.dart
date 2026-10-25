import 'dart:io';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:along_map/along_map.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/live_trip/presentation/trip_chat.dart';
import 'package:mobile_rider/config/app_config.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/offline/low_data_providers.dart';
import 'package:mobile_rider/features/payments/presentation/payment_deep_link_listener.dart';
import 'package:mobile_rider/features/tenant/tenant_providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/app_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlongRiderApp extends ConsumerWidget {
  const AlongRiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final brandingAsync = ref.watch(brandingOverridesProvider);
    final branding = brandingAsync.valueOrNull ?? BrandingOverrides.empty;

    return MaterialApp.router(
      title: 'Along',
      theme: alongTheme(branding: branding),
      darkTheme: alongTheme(branding: branding, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => PaymentDeepLinkListener(
        router: router,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Initializes Supabase and provider overrides for the app shell.
Future<ProviderContainer> bootstrapApp({AppConfig? configOverride}) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppStartupMetrics.instance.markBindingReady();

  final config = configOverride ?? AppConfig.fromEnvironment();
  final supabase = await createAlongSupabase(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  final mapDir = await getApplicationDocumentsDirectory();
  final mapCacheDir = Directory('${mapDir.path}/map_cache');

  final container = ProviderContainer(
    overrides: [
      ...buildProviderOverrides(
        config: config,
        supabase: supabase,
        ambientChannel: SupabaseAmbientChannel(Supabase.instance.client),
        negotiationChannel: SupabaseNegotiationChannel(
          Supabase.instance.client,
        ),
        database: await AlongDatabase.open(fileName: 'rider.db'),
        networkProbe: RiderNetworkProbe(),
        corridorTilePrecache: CorridorTilePrecacheService(
          cacheDirectory: mapCacheDir,
        ),
      ),
      tripChatChannelFactoryProvider.overrideWithValue(
        () => SupabaseTripChatChannel(Supabase.instance.client),
      ),
    ],
  );
  AppStartupMetrics.instance.markBootstrapComplete();
  return container;
}
