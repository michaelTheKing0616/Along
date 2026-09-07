import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';

/// Tenant branding from `deployments.branding_config` (token overrides only).
final brandingOverridesProvider = FutureProvider<BrandingOverrides>((ref) async {
  final config =
      await ref.read(catalogRepositoryProvider).brandingConfigForDefaultCountry();
  return BrandingOverrides.fromConfig(config);
});

/// Currency metadata for the driver's operating city.
final cityCurrencyMetaProvider = FutureProvider<CityCurrencyMeta>((ref) async {
  final cityId = ref.watch(homeControllerProvider.select((s) => s.cityId));
  final catalog = ref.read(catalogRepositoryProvider);
  if (cityId != null) {
    return catalog.currencyMetaForCity(cityId);
  }
  final country = await catalog.defaultActiveCountry();
  return CityCurrencyMeta(
    currencyCode: country.currencyCode,
    currencySymbol: country.currencySymbol,
    currencyMinorUnits: country.currencyMinorUnits,
  );
});

final appMoneyFormatterProvider = Provider<MoneyFormatter>((ref) {
  final meta = ref.watch(cityCurrencyMetaProvider).valueOrNull;
  return MoneyFormatter(
    currencyCode: meta?.currencyCode ?? 'NGN',
    currencySymbol: meta?.currencySymbol ?? '₦',
  );
});

String formatAppMoney(WidgetRef ref, Money money) =>
    ref.read(appMoneyFormatterProvider).format(money);

String formatAppMoneyMajor(WidgetRef ref, int amountMajor) =>
    ref.read(appMoneyFormatterProvider).formatMajor(amountMajor);
