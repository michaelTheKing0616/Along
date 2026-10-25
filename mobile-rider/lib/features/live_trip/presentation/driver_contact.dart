import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a `tel:` or `sms:` link. Overridden in tests.
final contactLauncherProvider = Provider<Future<void> Function(Uri uri)>(
  (ref) => (uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  },
);

Uri driverCallUri(String phone) => Uri(scheme: 'tel', path: phone);

Uri driverMessageUri(String phone) => Uri(scheme: 'sms', path: phone);
