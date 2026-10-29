import 'package:flutter/widgets.dart';
import 'package:along_design/along_design.dart';
import 'package:intl/intl.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Shared formatting for distances and fare tiers in the rider's language.
extension AlongL10nFormat on AppLocalizations {
  /// 850 → "850 m", 1800 → "1.8 km", 12400 → "12 km".
  String distance(num meters) {
    if (meters < 1000) {
      // Round to 10 m; finer reads as false precision on a city map.
      return distanceM(((meters / 10).round() * 10).toInt());
    }
    final km = meters / 1000;
    final f = NumberFormat(km < 10 ? '0.#' : '0', 'en');
    return distanceKm(f.format(km));
  }

  String fareTier(FareTier tier) => switch (tier) {
    FareTier.verified => fareTierVerified,
    FareTier.crowd => fareTierCrowd,
    FareTier.candidate => fareTierCandidate,
    FareTier.estimate => fareTierEstimate,
  };
}

/// Locale tag for `intl` date/number formats. intl has no data for ha, ig,
/// yo or pcm, so those fall back to English formats instead of throwing.
String intlLocaleOf(BuildContext context) {
  final tag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.localeExists(tag) ? tag : 'en';
}
