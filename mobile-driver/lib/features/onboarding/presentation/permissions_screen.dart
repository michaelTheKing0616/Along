import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/onboarding/presentation/auth_shared.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-04 Permission priming. Says why before the system asks, then one tap
/// raises the three system prompts in a row.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _asking = false;

  Future<void> _allow() async {
    setState(() => _asking = true);
    await ref.read(permissionPrimerProvider).requestAll();
    if (mounted) context.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlongAuthScaffold(
      title: l10n.permTitle,
      subtitle: l10n.permSubtitle,
      body: AlongPermissionPrime(
        items: [
          AlongPrimeItem(
            icon: AlongIcons.locate,
            title: l10n.permLocationTitle,
            body: l10n.permLocationBody,
          ),
          AlongPrimeItem(
            icon: AlongIcons.speaker,
            title: l10n.permNotifTitle,
            body: l10n.permNotifBody,
          ),
          AlongPrimeItem(
            icon: AlongIcons.camera,
            title: l10n.permCameraTitle,
            body: l10n.permCameraBody,
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AlongButton(
            key: const Key('permissions_allow'),
            label: l10n.permAllow,
            onPressed: _asking ? null : _allow,
            visualState: _asking
                ? AlongButtonVisualState.loading
                : AlongButtonVisualState.normal,
          ),
          const SizedBox(height: 8),
          AlongButton(
            key: const Key('permissions_later'),
            label: l10n.permLater,
            variant: AlongButtonVariant.tertiary,
            onPressed: _asking ? null : () => context.go(AppRoutes.profile),
          ),
        ],
      ),
    );
  }
}
