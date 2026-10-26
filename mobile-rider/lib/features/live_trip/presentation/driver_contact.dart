import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a `tel:` or `sms:` link. Overridden in tests.
final contactLauncherProvider = Provider<Future<void> Function(Uri uri)>(
  (ref) => (uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  },
);

/// Calls or texts the driver through the trip-contact relay. The trip payload
/// never carries the driver's number; the relay hands out a short-lived
/// action on tap.
Future<void> contactDriver(
  BuildContext context,
  WidgetRef ref, {
  required String tripId,
  required bool sms,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final action = await ref
        .read(tripsRepositoryProvider)
        .tripContact(tripId, sms ? 'sms' : 'call');
    if (action == null) throw StateError('no contact action');
    await ref.read(contactLauncherProvider)(action.uri);
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text("Can't reach your driver right now. Try again."),
      ),
    );
  }
}
