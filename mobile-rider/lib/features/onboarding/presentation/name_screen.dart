import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-04 Name (optional) — first launch only (doc 06 R-04).
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool includeName}) async {
    try {
      await ref.read(onboardingControllerProvider.notifier).completeOnboarding(
            displayName: includeName ? _controller.text.trim() : null,
          );
      if (mounted) context.go(AppRoutes.onboardingComplete);
    } catch (_) {
      // Error surfaced via controller state.
    }
  }

  String? _localizedError(AppLocalizations l10n, String? key) {
    return switch (key) {
      'generic' => l10n.errorGeneric,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AlongSpace.s32),
              Text(l10n.nameTitle, style: theme.textTheme.headlineLarge),
              const SizedBox(height: AlongSpace.s24),
              TextField(
                key: const Key('name_field'),
                controller: _controller,
                decoration: InputDecoration(
                  hintText: l10n.nameHint,
                  errorText: _localizedError(l10n, state.errorMessage),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AlongRadius.sm.x),
                  ),
                ),
              ),
              const Spacer(),
              AlongButton(
                key: const Key('name_continue_button'),
                label: l10n.continueButton,
                onPressed: state.isSubmitting
                    ? null
                    : () => _finish(includeName: true),
                visualState: state.isSubmitting
                    ? AlongButtonVisualState.loading
                    : AlongButtonVisualState.normal,
              ),
              const SizedBox(height: AlongSpace.s8),
              AlongButton(
                key: const Key('name_skip_button'),
                label: l10n.skip,
                variant: AlongButtonVariant.secondary,
                onPressed: state.isSubmitting
                    ? null
                    : () => _finish(includeName: false),
              ),
              const SizedBox(height: AlongSpace.s24),
            ],
          ),
        ),
      ),
    );
  }
}
