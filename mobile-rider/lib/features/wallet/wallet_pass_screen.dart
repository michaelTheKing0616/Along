import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_rider/features/wallet/wallet_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Buy rides ahead from wallet credit. Plans and the usual fare both come
/// from the server, so savings are computed from what the rider really paid.
class WalletPassScreen extends ConsumerStatefulWidget {
  const WalletPassScreen({super.key, this.initialPlan = 'week'});

  final String initialPlan;

  @override
  ConsumerState<WalletPassScreen> createState() => _WalletPassScreenState();
}

class _WalletPassScreenState extends ConsumerState<WalletPassScreen> {
  late String _plan = widget.initialPlan;
  bool _busy = false;
  bool _bought = false;
  String? _key;
  String? _error;

  void _pick(String plan) => setState(() {
    _plan = plan;
    _key = null;
    _error = null;
  });

  Future<void> _buy() async {
    final l10n = AppLocalizations.of(context);
    final key = _key ??= walletKey('pass');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(walletRepositoryProvider)
          .buyPass(plan: _plan, idempotencyKey: key);
      ref.invalidate(walletSummaryProvider);
      setState(() => _bought = true);
    } catch (e) {
      setState(() => _error = walletFailureText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(walletSummaryProvider)
        .when(
          skipLoadingOnRefresh: true,
          loading: () => const WalletLoadingView(),
          error: (_, _) => WalletErrorView(
            onRetry: () => ref.invalidate(walletSummaryProvider),
          ),
          data: (s) => _body(context, l10n, s),
        );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, WalletSummary s) {
    final p = AlongPalette.of(context);
    final plans = s.passPlans;
    final plan = plans.where((x) => x.id == _plan).firstOrNull ?? plans.first;
    final active = s.activePass;
    final until = active == null
        ? null
        : DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
              .format(active.expiresAt);
    final short = (plan.price - s.balance).clamp(0, plan.price);
    final Widget footer;
    if (_bought) {
      footer = AlongButton(
        key: const Key('wallet_pass_done'),
        label: l10n.walletPassBought,
        variant: AlongButtonVariant.secondary,
        onPressed: () => Navigator.of(context).maybePop(),
      );
    } else if (active != null) {
      footer = AlongButton(
        key: const Key('wallet_pass_active_cta'),
        label: l10n.walletPassActive(until!),
        variant: AlongButtonVariant.secondary,
        onPressed: null,
      );
    } else if (short > 0) {
      footer = AlongButton(
        key: const Key('wallet_pass_topup'),
        label: l10n.walletPassShort(alongNaira(short)),
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const WalletTopUpScreen()),
        ),
      );
    } else {
      footer = AlongButton(
        key: const Key('wallet_pass_cta'),
        label: l10n.walletPassCta(alongNaira(plan.price)),
        visualState: _busy
            ? AlongButtonVisualState.loading
            : AlongButtonVisualState.normal,
        onPressed: _busy ? null : _buy,
      );
    }
    final locked = _busy || _bought || active != null;
    return WalletPage(
      title: l10n.walletPassTitle,
      subtitle: l10n.walletPassSubtitle,
      footer: footer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < plans.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _PlanChip(
                    key: Key('wallet_pass_plan_${plans[i].id}'),
                    label: switch (plans[i].id) {
                      'week' => l10n.walletPassPlanWeek,
                      'pack' => l10n.walletPassPlanPack,
                      'month' => l10n.walletPassPlanMonth,
                      _ => l10n.walletPassRides(plans[i].rides),
                    },
                    selected: plans[i].id == plan.id,
                    onTap: locked ? null : () => _pick(plans[i].id),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            key: const Key('wallet_pass_card'),
            decoration: AlongCraft.surface(p, radius: AlongRadius.card.x),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.walletPassRides(plan.rides),
                          style: AlongType.title(p),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              alongNaira(plan.price),
                              key: const Key('wallet_pass_price'),
                              maxLines: 1,
                              style: AlongType.display(p).copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.walletPassPerRide(alongNaira(plan.perRide))} · '
                    '${l10n.walletPassValidity(plan.days)}',
                    style: AlongType.bodyMuted(p),
                  ),
                  if (active != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      key: const Key('wallet_pass_active'),
                      children: [
                        AlongIcon(
                          AlongIcons.verified,
                          size: 20,
                          color: p.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.walletPassActive(until!),
                            style: AlongType.label(p),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Versus(plan: plan, avgFare: s.avgFare),
          if (active == null) ...[
            const SizedBox(height: 24),
            _Section(
              title: l10n.walletPassHow,
              children: [
                for (final (i, t) in [
                  l10n.walletPassStep1,
                  l10n.walletPassStep2,
                  l10n.walletPassStep3(plan.days),
                ].indexed)
                  _Step(n: i + 1, text: t),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _Section(
            key: const Key('wallet_pass_details'),
            title: l10n.walletPassDetails,
            children: [
              _Row(l10n.walletPassRowRides, '${plan.rides}'),
              _Row(
                l10n.walletPassRowValid,
                DateFormat.yMMMd(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(
                  active?.expiresAt ??
                      ref
                          .watch(walletNowProvider)()
                          .add(Duration(days: plan.days)),
                ),
              ),
              _Row(l10n.walletPassRowPaid, l10n.walletPassRowPaidValue),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.walletAvailable(alongNaira(s.balance)),
            key: const Key('wallet_pass_balance'),
            style: AlongType.caption(p),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                key: const Key('wallet_pass_error'),
                style: AlongType.body(p).copyWith(color: p.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? p.ink : p.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? p.ink : p.line),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AlongType.label(p)
                        .copyWith(color: selected ? p.onInk : p.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pass price against the same number of single fares at the rider's own
/// average fare. Says so plainly when there is no history or no saving.
class _Versus extends StatelessWidget {
  const _Versus({required this.plan, required this.avgFare});

  final WalletPassPlan plan;
  final int? avgFare;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final save = plan.savingVs(avgFare);
    Widget row(String a, String b, {TextStyle? style, Key? key}) => Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(a, style: style ?? AlongType.body(p))),
          const SizedBox(width: 12),
          Text(
            b,
            style: (style ?? AlongType.body(p)).copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    return DecoratedBox(
      key: const Key('wallet_pass_versus'),
      decoration: AlongCraft.surface(p, radius: AlongRadius.card.x),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.walletPassVersus, style: AlongType.label(p)),
            const SizedBox(height: 4),
            if (avgFare == null)
              Text(
                l10n.walletPassNoHistory,
                key: const Key('wallet_pass_no_history'),
                style: AlongType.bodyMuted(p),
              )
            else ...[
              row(
                l10n.walletPassSingleRow(plan.rides, alongNaira(avgFare!)),
                alongNaira(avgFare! * plan.rides),
              ),
              row(l10n.walletPassPassRow, alongNaira(plan.price)),
              Divider(
                height: 16,
                thickness: 1,
                color: p.line.withValues(alpha: 0.5),
              ),
              if (save! > 0)
                row(
                  l10n.walletPassSaveLabel,
                  alongNaira(save),
                  key: const Key('wallet_pass_save'),
                  style: AlongType.label(p).copyWith(color: p.success),
                )
              else
                Text(
                  l10n.walletPassNoSave,
                  key: const Key('wallet_pass_no_save'),
                  style: AlongType.bodyMuted(p),
                ),
              const SizedBox(height: 4),
              Text(
                l10n.walletPassUsualFare(alongNaira(avgFare!)),
                style: AlongType.caption(p),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: AlongType.label(p))),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
            child: Text(
              '$n',
              style: AlongType.caption(p)
                  .copyWith(color: p.onInk, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AlongType.body(p))),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: p.line.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AlongType.bodyMuted(p))),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AlongType.body(p).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
