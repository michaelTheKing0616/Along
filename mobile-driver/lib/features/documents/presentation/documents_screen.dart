import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/documents/presentation/document_capture_screen.dart';
import 'package:mobile_driver/features/documents/presentation/documents_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-06 Documents checklist (doc 06 D-06).
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  String _statusLabel(AppLocalizations l10n, DocumentUiStatus status) {
    return switch (status) {
      DocumentUiStatus.notStarted => l10n.docStatusNotStarted,
      DocumentUiStatus.pending => l10n.docStatusPending,
      DocumentUiStatus.approved => l10n.docStatusApproved,
      DocumentUiStatus.rejected => l10n.docStatusRejected,
    };
  }

  Color _statusColor(DocumentUiStatus status) {
    return switch (status) {
      DocumentUiStatus.approved => AlongColors.semanticSuccessFill,
      DocumentUiStatus.rejected => AlongColors.semanticDangerFill,
      DocumentUiStatus.pending => AlongColors.brandYellow,
      DocumentUiStatus.notStarted => AlongColors.ink300,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncState = ref.watch(documentsControllerProvider);
    final theme = Theme.of(context);

    ref.listen(documentsControllerProvider, (previous, next) {
      next.whenData((state) {
        if (state.allSubmitted && context.mounted) {
          context.go(AppRoutes.pending);
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.documentsTitle),
        backgroundColor: AlongColors.surface0,
        elevation: 0,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.errorGeneric)),
        data: (state) {
          if (state.errorMessage != null) {
            return Center(child: Text(l10n.errorGeneric));
          }

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AlongSpace.s24),
                  child: Text(
                    l10n.documentsSubtitle,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      final canCapture = item.status == DocumentUiStatus.notStarted ||
                          item.status == DocumentUiStatus.rejected;

                      return ListTile(
                        key: Key('doc_row_${item.type}'),
                        title: Text(item.label),
                        subtitle: item.rejectionReason == null
                            ? null
                            : Text(item.rejectionReason!),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AlongSpace.s8,
                            vertical: AlongSpace.s4,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(item.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AlongRadius.sm.x),
                          ),
                          child: Text(
                            _statusLabel(l10n, item.status),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AlongColors.ink900,
                            ),
                          ),
                        ),
                        onTap: canCapture
                            ? () {
                                context.push(
                                  AppRoutes.documentCapture,
                                  extra: DocumentCaptureRouteArgs(
                                    documentType: item.type,
                                    label: item.label,
                                  ),
                                );
                              }
                            : null,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AlongSpace.s24),
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.pending),
                    child: Text(l10n.saveAndContinueLater),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
