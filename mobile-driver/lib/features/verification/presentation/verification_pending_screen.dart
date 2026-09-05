import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/documents/presentation/documents_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-07 Verification pending (doc 06 D-07).
class VerificationPendingScreen extends ConsumerWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final expectedHoursAsync = ref.watch(_expectedReviewHoursProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AlongSpace.s32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AlongSpace.s24),
                decoration: BoxDecoration(
                  color: AlongColors.brandYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AlongRadius.lg.x),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pendingHero,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AlongSpace.s12),
                    expectedHoursAsync.when(
                      data: (hours) => Text(
                        hours == null
                            ? l10n.pendingExpectedGeneric
                            : l10n.pendingExpectedHours(hours),
                        style: theme.textTheme.bodyLarge,
                      ),
                      loading: () => Text(
                        l10n.pendingExpectedGeneric,
                        style: theme.textTheme.bodyLarge,
                      ),
                      error: (_, __) => Text(
                        l10n.pendingExpectedGeneric,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AlongSpace.s24),
              Text(l10n.pendingWhatNext, style: theme.textTheme.bodyLarge),
              const Spacer(),
              AlongButton(
                key: const Key('setup_route_button'),
                label: l10n.setupRouteCta,
                onPressed: () => context.go(AppRoutes.routesTab),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _expectedReviewHoursProvider = FutureProvider<int?>((ref) async {
  return ref.read(documentsControllerProvider.notifier).expectedReviewHours();
});
