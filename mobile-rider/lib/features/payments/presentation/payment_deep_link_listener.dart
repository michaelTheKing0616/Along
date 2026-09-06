import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/payments/domain/qr_payload_parser.dart';
import 'package:mobile_rider/routing/routes.dart';

/// Cold + warm universal link handling for `along.ng/p/:code` and `along://p/:code`.
class PaymentDeepLinkListener extends ConsumerStatefulWidget {
  const PaymentDeepLinkListener({
    super.key,
    required this.child,
    required this.router,
  });

  final Widget child;
  final GoRouter router;

  @override
  ConsumerState<PaymentDeepLinkListener> createState() =>
      _PaymentDeepLinkListenerState();
}

class _PaymentDeepLinkListenerState
    extends ConsumerState<PaymentDeepLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _handleInitialLink();
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  Future<void> _handleInitialLink() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handleUri(initial);
    }
  }

  void _handleUri(Uri uri) {
    final code = QrPayloadParser.parse(uri.toString());
    if (code == null) return;
    final token = uri.queryParameters['t'];
    widget.router.push(
      AppRoutes.payDriver,
      extra: PayDriverRouteArgs(driverCode: code, dynamicToken: token),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Route extra for universal-link / scan → R-27.
class PayDriverRouteArgs {
  const PayDriverRouteArgs({
    this.trip,
    this.driverCode,
    this.dynamicToken,
    this.preloadedResolve,
  });

  final dynamic trip;
  final String? driverCode;
  final String? dynamicToken;
  final dynamic preloadedResolve;
}
