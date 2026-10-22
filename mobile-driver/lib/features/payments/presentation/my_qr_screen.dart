import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/features/payments/presentation/my_qr_controller.dart';
import 'package:mobile_driver/features/payments/presentation/widgets/along_qr_widget.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// D-25 My QR code — static QR, share, sticker, verify, pause, rotate (doc 06).
class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(myQrControllerProvider);
    final controller = ref.read(myQrControllerProvider.notifier);
    final qrUrl = controller.staticQrUrl();

    return Scaffold(
      key: const Key('my_qr_screen'),
      appBar: AppBar(
        title: Text(l10n.myQrTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AlongSpace.s16),
              children: [
                if (!state.digitalEnabled) ...[
                  _InfoCard(text: l10n.myQrDigitalDisabledBanner),
                  const SizedBox(height: AlongSpace.s16),
                ],
                if (state.showPayoutPrompt) ...[
                  Text(l10n.myQrPayoutPrompt, style: AlongText.heading2),
                  const SizedBox(height: AlongSpace.s8),
                  Text(
                    l10n.myQrPayoutHint,
                    style: AlongText.body.copyWith(color: AlongColors.ink500),
                  ),
                  const SizedBox(height: AlongSpace.s16),
                  AlongButton(
                    key: const Key('my_qr_setup_payout'),
                    label: l10n.myQrSetupPayout,
                    variant: AlongButtonVariant.secondary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.myQrPayoutComingSoon)),
                      );
                    },
                  ),
                ] else if (qrUrl != null && state.profile?.driverCode != null) ...[
                  Center(
                    child: AlongQrWidget(
                      data: qrUrl,
                      plate: state.profile!.plate,
                    ),
                  ),
                  const SizedBox(height: AlongSpace.s12),
                  Center(
                    child: Text(
                      state.profile!.driverCode!,
                      style: AlongText.displayL,
                    ),
                  ),
                  if (state.digitalPaused) ...[
                    const SizedBox(height: AlongSpace.s12),
                    _InfoCard(text: l10n.myQrPausedBanner),
                  ],
                  const SizedBox(height: AlongSpace.s24),
                  AlongButton(
                    key: const Key('my_qr_share'),
                    label: l10n.myQrShare,
                    onPressed: state.isBusy ? null : controller.shareImage,
                  ),
                  const SizedBox(height: AlongSpace.s8),
                  AlongButton(
                    key: const Key('my_qr_order_sticker'),
                    label: l10n.myQrOrderSticker,
                    variant: AlongButtonVariant.secondary,
                    visualState: state.isBusy
                        ? AlongButtonVisualState.loading
                        : AlongButtonVisualState.normal,
                    onPressed: state.isBusy ? null : controller.orderSticker,
                  ),
                  if (state.stickerRequests.isNotEmpty) ...[
                    const SizedBox(height: AlongSpace.s8),
                    Text(
                      l10n.myQrStickerStatus(
                        state.stickerRequests.first.status,
                      ),
                      style: AlongText.caption,
                    ),
                  ],
                  const SizedBox(height: AlongSpace.s8),
                  AlongButton(
                    key: const Key('my_qr_verify_sticker'),
                    label: l10n.myQrVerifySticker,
                    variant: AlongButtonVariant.secondary,
                    onPressed: state.isBusy
                        ? null
                        : () => controller.verifySticker(
                              ref.read(qrScannerProvider),
                            ),
                  ),
                  if (state.verifyMessage != null) ...[
                    const SizedBox(height: AlongSpace.s8),
                    Text(
                      _verifyText(l10n, state.verifyMessage!),
                      style: AlongText.caption.copyWith(
                        color: state.verifyMessage == 'match'
                            ? AlongColors.semanticSuccessFill
                            : AlongColors.semanticDanger,
                      ),
                    ),
                  ],
                  const SizedBox(height: AlongSpace.s16),
                  SwitchListTile(
                    key: const Key('my_qr_pause_toggle'),
                    title: Text(l10n.myQrPauseDigital),
                    subtitle: Text(l10n.myQrPauseDigitalHint),
                    value: state.profile!.acceptsDigital,
                    onChanged: state.isBusy || !state.digitalEnabled
                        ? null
                        : (value) => controller.toggleAcceptsDigital(value),
                  ),
                  const SizedBox(height: AlongSpace.s8),
                  AlongButton(
                    key: const Key('my_qr_rotate'),
                    label: l10n.myQrRotate,
                    variant: AlongButtonVariant.danger,
                    onPressed: state.isBusy
                        ? null
                        : () => _confirmRotate(context, l10n, controller),
                  ),
                ],
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AlongSpace.s12),
                  Text(
                    l10n.errorGeneric,
                    style: AlongText.caption.copyWith(
                      color: AlongColors.semanticDanger,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  String _verifyText(AppLocalizations l10n, String code) => switch (code) {
        'match' => l10n.myQrVerifyMatch,
        'mismatch' => l10n.myQrVerifyMismatch,
        'invalid' => l10n.myQrVerifyInvalid,
        'timeout' => l10n.myQrVerifyTimeout,
        _ => l10n.errorGeneric,
      };

  Future<void> _confirmRotate(
    BuildContext context,
    AppLocalizations l10n,
    MyQrController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.myQrRotateConfirmTitle),
        content: Text(l10n.myQrRotateConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.myQrRotateCancel),
          ),
          TextButton(
            key: const Key('my_qr_rotate_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.myQrRotateConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.rotateCode();
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AlongSpace.s12),
      decoration: BoxDecoration(
        color: AlongColors.surface0,
        borderRadius: BorderRadius.circular(AlongRadius.sm.x),
      ),
      child: Text(text, style: AlongText.body),
    );
  }
}
