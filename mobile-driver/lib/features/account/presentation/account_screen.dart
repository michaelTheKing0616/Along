import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-24 Account stub with My QR entry (doc 06).
class AccountStubScreen extends StatelessWidget {
  const AccountStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('account_screen'),
      appBar: AppBar(
        title: Text(l10n.navAccount),
        backgroundColor: AlongColors.surface0,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            key: const Key('account_my_qr_link'),
            title: Text(l10n.myQrTitle),
            subtitle: Text(l10n.myQrAccountSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.myQr),
          ),
        ],
      ),
    );
  }
}
