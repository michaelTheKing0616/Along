import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/features/payments/presentation/my_qr_controller.dart';
import 'package:mobile_driver/features/payments/presentation/widgets/along_qr_widget.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// D-25 My QR code — static QR, share, sticker, verify, pause, rotate (doc 06).
class MyQrScreen extends ConsumerWidget {
  const MyQrScreen({super.key, this.renderQrPixels});

  /// Forces QR painting (goldens); null paints in app, stubs in tests.
  final bool? renderQrPixels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final state = ref.watch(myQrControllerProvider);
    final controller = ref.read(myQrControllerProvider.notifier);
    final qrUrl = controller.staticQrUrl();
    final profile = state.profile;
    final hasCode = qrUrl != null && profile?.driverCode != null;
    final busy = state.isBusy;

    return Scaffold(
      key: const Key('my_qr_screen'),
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AlongSpace.s16,
                AlongSpace.s8,
                AlongSpace.s16,
                0,
              ),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    AlongMapButton(
                      key: const Key('my_qr_back'),
                      icon: AlongIcons.back,
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AlongSpace.s20,
                        AlongSpace.s16,
                        AlongSpace.s20,
                        AlongSpace.s24,
                      ),
                      children: [
                        Text(l10n.myQrTitle, style: AlongType.display(p)),
                        const SizedBox(height: AlongSpace.s4),
                        Text(
                          l10n.myQrAccountSubtitle,
                          style: AlongType.bodyMuted(p),
                        ),
                        const SizedBox(height: AlongSpace.s20),
                        if (!state.digitalEnabled) ...[
                          _Notice(text: l10n.myQrDigitalDisabledBanner),
                          const SizedBox(height: AlongSpace.s12),
                        ],
                        if (state.showPayoutPrompt) ...[
                          _Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AlongIcon(
                                  AlongIcons.bank,
                                  size: 28,
                                  color: p.ink,
                                ),
                                const SizedBox(height: AlongSpace.s12),
                                Text(
                                  l10n.myQrPayoutPrompt,
                                  style: AlongType.title(p),
                                ),
                                const SizedBox(height: AlongSpace.s4),
                                Text(
                                  l10n.myQrPayoutHint,
                                  style: AlongType.bodyMuted(p),
                                ),
                              ],
                            ),
                          ),
                        ] else if (hasCode) ...[
                          _Panel(
                            padding: const EdgeInsets.all(AlongSpace.s20),
                            child: Column(
                              children: [
                                AlongQrWidget(
                                  data: qrUrl,
                                  size: 200,
                                  renderPixels: renderQrPixels,
                                ),
                                const SizedBox(height: AlongSpace.s16),
                                Text(
                                  profile!.driverCode!,
                                  style: AlongText.displayL.copyWith(
                                    color: p.ink,
                                    letterSpacing: 2,
                                  ),
                                ),
                                if (profile.plate.isNotEmpty) ...[
                                  const SizedBox(height: AlongSpace.s4),
                                  Text(
                                    profile.plate,
                                    style: AlongType.bodyMuted(p),
                                  ),
                                ],
                                const SizedBox(height: AlongSpace.s16),
                                AlongButton(
                                  key: const Key('my_qr_share'),
                                  label: l10n.myQrShare,
                                  onPressed: busy
                                      ? null
                                      : controller.shareImage,
                                ),
                              ],
                            ),
                          ),
                          if (state.digitalPaused) ...[
                            const SizedBox(height: AlongSpace.s12),
                            _Notice(text: l10n.myQrPausedBanner),
                          ],
                          const SizedBox(height: AlongSpace.s20),
                          _ActionRow(
                            key: const Key('my_qr_order_sticker'),
                            icon: AlongIcons.receipt,
                            label: l10n.myQrOrderSticker,
                            caption: state.stickerRequests.isEmpty
                                ? null
                                : l10n.myQrStickerStatus(
                                    state.stickerRequests.first.status,
                                  ),
                            onTap: busy ? null : controller.orderSticker,
                          ),
                          const SizedBox(height: AlongSpace.s8),
                          _ActionRow(
                            key: const Key('my_qr_verify_sticker'),
                            icon: AlongIcons.verified,
                            label: l10n.myQrVerifySticker,
                            caption: state.verifyMessage == null
                                ? null
                                : _verifyText(l10n, state.verifyMessage!),
                            captionColor: state.verifyMessage == null
                                ? null
                                : state.verifyMessage == 'match'
                                ? p.success
                                : p.danger,
                            onTap: busy
                                ? null
                                : () => controller.verifySticker(
                                    ref.read(qrScannerProvider),
                                  ),
                          ),
                          const SizedBox(height: AlongSpace.s8),
                          _Panel(
                            padding: const EdgeInsets.fromLTRB(
                              AlongSpace.s16,
                              AlongSpace.s8,
                              AlongSpace.s8,
                              AlongSpace.s8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.myQrPauseDigital,
                                        style: AlongType.label(p),
                                      ),
                                      Text(
                                        l10n.myQrPauseDigitalHint,
                                        style: AlongType.caption(p),
                                      ),
                                    ],
                                  ),
                                ),
                                // The switch reads "Pause": on means paused.
                                AlongSwitch(
                                  key: const Key('my_qr_pause_toggle'),
                                  semanticLabel: l10n.myQrPauseDigital,
                                  value: !profile.acceptsDigital,
                                  onChanged: busy || !state.digitalEnabled
                                      ? null
                                      : (paused) => controller
                                            .toggleAcceptsDigital(!paused),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AlongSpace.s8),
                          _ActionRow(
                            key: const Key('my_qr_rotate'),
                            icon: AlongIcons.history,
                            label: l10n.myQrRotate,
                            danger: true,
                            onTap: busy
                                ? null
                                : () =>
                                      _confirmRotate(context, l10n, controller),
                          ),
                        ],
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: AlongSpace.s12),
                          _Notice(text: l10n.errorGeneric),
                        ],
                      ],
                    ),
            ),
            if (!state.isLoading && state.showPayoutPrompt)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AlongSpace.s20,
                  AlongSpace.s8,
                  AlongSpace.s20,
                  AlongSpace.s12,
                ),
                child: AlongButton(
                  key: const Key('my_qr_setup_payout'),
                  label: l10n.myQrSetupPayout,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.myQrPayoutComingSoon)),
                    );
                  },
                ),
              ),
          ],
        ),
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

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.compactFill(p.recessed, 64, corner: 20),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AlongSpace.s16),
        child: child,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AlongCraft.fill(AlongColors.semanticWarningTint, corner: 16),
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AlongIcon(
              AlongIcons.info,
              size: 20,
              color: AlongColors.semanticWarning,
            ),
            const SizedBox(width: AlongSpace.s8),
            Expanded(
              child: Text(
                text,
                style: AlongText.body.copyWith(color: AlongColors.ink900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width action: icon, label, optional status caption, caret.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
    this.captionColor,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? caption;
  final Color? captionColor;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final fg = danger ? p.danger : p.ink;
    return Material(
      color: p.recessed,
      shape: AlongCraft.border(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AlongSpace.s16,
              vertical: AlongSpace.s12,
            ),
            child: Row(
              children: [
                AlongIcon(icon, size: 24, color: fg),
                const SizedBox(width: AlongSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: AlongType.label(p).copyWith(color: fg),
                      ),
                      if (caption != null)
                        Text(
                          caption!,
                          style: AlongType.caption(p)
                              .copyWith(color: captionColor),
                        ),
                    ],
                  ),
                ),
                AlongIcon(AlongIcons.caretRight, size: 20, color: p.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
