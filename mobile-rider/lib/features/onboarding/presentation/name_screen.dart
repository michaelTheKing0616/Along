import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/onboarding/presentation/onboarding_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-04 Name (optional), first launch only (doc 06 R-04).
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool includeName}) async {
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding(
            displayName: includeName ? _controller.text.trim() : null,
          );
      if (mounted) context.go(AppRoutes.permissions);
    } catch (_) {
      // Shown inline from controller state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final p = AlongPalette.of(context);
    final style = AlongType.title(p);
    final hasName = _controller.text.trim().isNotEmpty;

    return AlongAuthScaffold(
      title: l10n.nameTitle,
      subtitle: l10n.nameSubtitle,
      notice: state.errorMessage == 'generic'
          ? AlongAuthNotice(
              tone: AlongAuthNoticeTone.error,
              message: l10n.errorGeneric,
            )
          : null,
      body: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: AlongCraft.fill(
          p.surface,
          corner: AlongRadius.control.x,
          side: BorderSide(color: p.line),
        ),
        alignment: Alignment.centerLeft,
        child: TextField(
          key: const Key('name_field'),
          controller: _controller,
          autofocus: true,
          autofillHints: const [AutofillHints.givenName],
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _finish(includeName: hasName),
          style: style,
          cursorColor: p.ink,
          decoration: InputDecoration(
            hintText: l10n.nameHint,
            hintStyle: style.copyWith(color: p.muted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AlongButton(
            key: const Key('name_continue_button'),
            label: l10n.continueButton,
            onPressed: state.isSubmitting || !hasName
                ? null
                : () => _finish(includeName: true),
            visualState: state.isSubmitting
                ? AlongButtonVisualState.loading
                : AlongButtonVisualState.normal,
          ),
          const SizedBox(height: 8),
          AlongButton(
            key: const Key('name_skip_button'),
            label: l10n.skip,
            variant: AlongButtonVariant.tertiary,
            onPressed: state.isSubmitting
                ? null
                : () => _finish(includeName: false),
          ),
        ],
      ),
    );
  }
}
