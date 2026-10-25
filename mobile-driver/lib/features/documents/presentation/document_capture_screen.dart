import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/onboarding/data/driver_onboarding_preferences.dart';
import 'package:mobile_driver/features/documents/domain/ocr_confirm_policy.dart';
import 'package:mobile_driver/features/documents/presentation/documents_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/app_router.dart';
import 'package:mobile_driver/routing/routes.dart';

class DocumentCaptureRouteArgs {
  const DocumentCaptureRouteArgs({
    required this.documentType,
    required this.label,
  });

  final String documentType;
  final String label;
}

/// D-06 document capture with OCR-assist confirm (doc 06 D-06).
class DocumentCaptureScreen extends ConsumerStatefulWidget {
  const DocumentCaptureScreen({super.key, required this.args});

  final DocumentCaptureRouteArgs args;

  @override
  ConsumerState<DocumentCaptureScreen> createState() =>
      _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends ConsumerState<DocumentCaptureScreen> {
  late final DocumentCaptureArgs _controllerArgs;
  final _manualControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _controllerArgs = DocumentCaptureArgs(
      documentType: widget.args.documentType,
      label: widget.args.label,
    );
  }

  @override
  void dispose() {
    for (final controller in _manualControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key) {
    return _manualControllers.putIfAbsent(key, TextEditingController.new);
  }

  Future<void> _useTestImage() async {
    // Minimal JPEG header bytes for widget/integration tests (no camera).
    const fakeJpeg = <int>[0xFF, 0xD8, 0xFF, 0xD9];
    final ocrHints = widget.args.documentType == 'nin'
        ? {'nin': '12345678901', 'full_name': 'Test Driver'}
        : {'full_name': 'Test Driver'};

    await ref
        .read(documentCaptureControllerProvider(_controllerArgs).notifier)
        .attachImage(fakeJpeg, ocrHints: ocrHints);
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(documentCaptureControllerProvider(_controllerArgs).notifier)
        .submit();
    if (!ok || !mounted) return;

    final refreshed =
        await ref.read(documentsControllerProvider.notifier).refreshAndGetState();
    if (!mounted) return;

    final step = await ref.read(driverOnboardingPreferencesProvider).currentStep();
    if (!mounted) return;
    if (step == DriverOnboardingStep.pending || refreshed.allSubmitted) {
      ref.read(routerProvider).go(AppRoutes.pending);
    } else {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(documentCaptureControllerProvider(_controllerArgs));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.captureTitle(widget.args.label)),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AlongSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.captureGuide, style: theme.textTheme.bodyLarge),
              const SizedBox(height: AlongSpace.s16),
              if (state.imageBytes == null)
                AlongButton(
                  key: const Key('capture_test_image_button'),
                  label: l10n.takePhoto,
                  onPressed: _useTestImage,
                )
              else ...[
                Container(
                  height: 160,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: AlongCraft.fill(
                    AlongColors.ink100,
                    corner: AlongRadius.card.x,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image, size: 48),
                ),
                const SizedBox(height: AlongSpace.s16),
                Text(l10n.ocrReviewTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: AlongSpace.s8),
                Text(
                  l10n.ocrNoAutoFillNote,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AlongSpace.s16),
                for (final entry in state.ocrSuggestions.entries) ...[
                  Text(entry.key, style: theme.textTheme.labelLarge),
                  const SizedBox(height: AlongSpace.s4),
                  Text(
                    l10n.ocrSuggestedValue(entry.value),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AlongSpace.s8),
                  TextField(
                    key: Key('ocr_field_${entry.key}'),
                    controller: _controllerFor(entry.key),
                    decoration: InputDecoration(
                      hintText: entry.value,
                    ),
                    onChanged: (value) {
                      ref
                          .read(
                            documentCaptureControllerProvider(_controllerArgs)
                                .notifier,
                          )
                          .setManualField(entry.key, value);
                    },
                  ),
                  const SizedBox(height: AlongSpace.s8),
                  if (!state.appliedSuggestionKeys.contains(entry.key))
                    TextButton(
                      key: Key('ocr_confirm_${entry.key}'),
                      onPressed: () {
                        ref
                            .read(
                              documentCaptureControllerProvider(_controllerArgs)
                                  .notifier,
                            )
                            .confirmSuggestion(entry.key);
                        _controllerFor(entry.key).text = entry.value;
                      },
                      child: Text(l10n.ocrConfirmField),
                    )
                  else
                    Text(
                      l10n.ocrFieldConfirmed,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AlongColors.semanticSuccessFill,
                      ),
                    ),
                  const SizedBox(height: AlongSpace.s16),
                ],
                if (state.ocrSuggestions.entries.any(
                  (e) => OcrConfirmPolicy.isSensitiveField(e.key),
                ))
                  Text(
                    l10n.ocrNoAutoFillNote,
                    key: const Key('ocr_sensitive_note'),
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: AlongSpace.s24),
                Row(
                  children: [
                    Expanded(
                      child: AlongButton(
                        label: l10n.retakePhoto,
                        variant: AlongButtonVariant.secondary,
                        onPressed: () {
                          for (final controller in _manualControllers.values) {
                            controller.clear();
                          }
                          ref
                              .read(
                                documentCaptureControllerProvider(_controllerArgs)
                                    .notifier,
                              )
                              .resetCapture();
                        },
                      ),
                    ),
                    const SizedBox(width: AlongSpace.s12),
                    Expanded(
                      child: AlongButton(
                        key: const Key('submit_document_button'),
                        label: l10n.submitDocument,
                        onPressed: state.isSubmitting ? null : _submit,
                        visualState: state.isSubmitting
                            ? AlongButtonVisualState.loading
                            : AlongButtonVisualState.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
