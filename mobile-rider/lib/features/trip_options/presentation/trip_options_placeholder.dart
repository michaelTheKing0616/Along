import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-07 stub — trip options arrive in P1-B-03.
class TripOptionsPlaceholderScreen extends StatelessWidget {
  const TripOptionsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripOptionsStubTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s24),
          child: Text(
            l10n.tripOptionsStubBody,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
