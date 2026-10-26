import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/features/ledger/presentation/ledger_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';

/// D-20 Settle — prefilled amount, channels, agent code (doc 06).
class SettleScreen extends ConsumerStatefulWidget {
  const SettleScreen({super.key});

  @override
  ConsumerState<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends ConsumerState<SettleScreen> {
  late final TextEditingController _amountController;
  String? _activeSettlementId;
  String? _agentCode;
  String? _agentExpiresAt;
  List<NearbySettlementAgent> _nearbyAgents = const [];
  String? _statusMessage;
  String? _channelDetail;
  bool _busy = false;
  String? _currencySymbol;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillAmount();
      _loadCurrencySymbol();
    });
  }

  Future<void> _loadCurrencySymbol() async {
    final cityId = ref.read(driverHomeControllerProvider).cityId;
    if (cityId == null) return;
    try {
      final meta = await ref
          .read(catalogRepositoryProvider)
          .currencyMetaForCity(cityId);
      if (mounted) setState(() => _currencySymbol = meta.currencySymbol);
    } catch (_) {
      // Balance currency code still applies; symbol falls back in formatMoney.
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _prefillAmount() {
    final ledger = ref.read(driverLedgerControllerProvider);
    if (ledger.balance.amount >= Decimal.zero) {
      _amountController.text = '100';
      return;
    }
    final toZero = (-ledger.balance.amount).toStringAsFixed(0);
    _amountController.text = toZero;
  }

  Money _parseAmount(String currency) {
    final parsed = double.tryParse(_amountController.text.trim()) ?? 0;
    return Money.parse(parsed.toStringAsFixed(2), currency: currency);
  }

  String _formatMinimumAmount(String currency) {
    return formatMoney(
      Money.parse('100', currency: currency),
      currencySymbol: _currencySymbol,
    );
  }

  Future<void> _initiateChannel(String channel) async {
    setState(() {
      _busy = true;
      _statusMessage = null;
      _channelDetail = null;
      _agentCode = null;
      _nearbyAgents = const [];
    });
    try {
      final currency = ref
          .read(driverLedgerControllerProvider)
          .balance
          .currency;
      final amount = _parseAmount(currency);
      if (amount.amount <= Decimal.zero) {
        setState(
          () => _statusMessage =
              'Enter at least ${_formatMinimumAmount(currency)}',
        );
        return;
      }
      final repo = ref.read(ledgerRepositoryProvider);
      if (channel == 'agent') {
        final code = await repo.createAgentCode(amount: amount);
        final agents = await repo.nearbySettlementAgents();
        setState(() {
          _agentCode = code.agent_code;
          _agentExpiresAt = code.expires_at;
          _nearbyAgents = agents;
          _statusMessage = 'Show this code to an Along agent within 15 minutes';
        });
        return;
      }
      final result = await repo.initiateSettlement(
        amount: amount,
        channel: channel,
      );
      _activeSettlementId = result.settlementId;
      if (result.authorizationUrl != null) {
        _channelDetail = result.authorizationUrl;
      } else if (result.ussdCode != null) {
        _channelDetail = result.ussdCode;
      } else if (result.bankAccount != null) {
        _channelDetail = result.bankAccount.toString();
      }
      _startPolling(result.settlementId);
      setState(() {
        _statusMessage = 'Complete payment to settle your balance';
      });
    } catch (_) {
      setState(
        () =>
            _statusMessage = 'Could not start settlement — try another channel',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling(String settlementId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final snapshot = await ref
          .read(ledgerRepositoryProvider)
          .settlementStatus(settlementId);
      if (!mounted || snapshot == null) return;
      if (snapshot.status == 'confirmed') {
        _pollTimer?.cancel();
        await ref.read(driverLedgerControllerProvider.notifier).refresh();
        setState(() {
          _statusMessage = 'Settled — balance updated';
        });
      } else if (snapshot.status == 'failed' || snapshot.status == 'expired') {
        _pollTimer?.cancel();
        setState(() {
          _statusMessage = 'Settlement ${snapshot.status} — try again';
        });
      }
    });
  }

  String _channel = 'paystack_transfer';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final ledger = ref.watch(driverLedgerControllerProvider);
    final owes = ledger.balance.amount < Decimal.zero;
    String money(Money m) => formatMoney(m, currencySymbol: _currencySymbol);
    final abs = owes
        ? Money.parse(
            (-ledger.balance.amount).toString(),
            currency: ledger.balance.currency,
          )
        : ledger.balance;
    final entered = _parseAmount(ledger.balance.currency);
    final channels = <(String, Key, String, String, IconData)>[
      (
        'paystack_transfer',
        const Key('settle_bank'),
        l10n.settleChannelBank,
        l10n.settleChannelBankDetail,
        AlongIcons.storefront,
      ),
      (
        'paystack_ussd',
        const Key('settle_ussd'),
        l10n.settleChannelUssd,
        l10n.settleChannelUssdDetail,
        AlongIcons.password,
      ),
      (
        'paystack_card',
        const Key('settle_card'),
        l10n.settleChannelCard,
        l10n.settleChannelCardDetail,
        AlongIcons.schedule,
      ),
      (
        'agent',
        const Key('settle_agent'),
        l10n.settleChannelAgent,
        l10n.settleChannelAgentDetail,
        AlongIcons.user,
      ),
    ];

    return KeyedSubtree(
      key: const Key('settle_screen'),
      child: DrivePage(
        title: l10n.settleTitle,
        subtitle: l10n.settleSubtitle,
        footer: _agentCode != null || _activeSettlementId != null
            ? AlongButton(
                key: const Key('settle_done'),
                label: l10n.settleDone,
                onPressed: () => context.pop(),
              )
            : AlongButton(
                key: const Key('settle_submit'),
                label: l10n.settleSubmit(money(entered)),
                visualState: _busy
                    ? AlongButtonVisualState.loading
                    : AlongButtonVisualState.normal,
                onPressed: _busy ? null : () => _initiateChannel(_channel),
              ),
        children: [
          DriveCard(
            key: const Key('settle_balance_hero'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  owes ? l10n.settleOwedLabel : l10n.settleCreditLabel,
                  style: AlongType.caption(p),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    money(abs),
                    style: AlongType.display(
                      p,
                    ).copyWith(fontSize: 40, fontFeatures: AlongType.figures),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settleThreshold(
                    money(
                      Money.parse(
                        ledger.blockThreshold.amount.abs().toString(),
                        currency: ledger.blockThreshold.currency,
                      ),
                    ),
                  ),
                  style: AlongType.bodyMuted(p),
                ),
              ],
            ),
          ),
          DriveSection(l10n.settleAmountLabel),
          TextField(
            key: const Key('settle_amount_field'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            style: AlongType.title(p).copyWith(fontFeatures: AlongType.figures),
            decoration: InputDecoration(
              filled: true,
              fillColor: p.recessed,
              prefixText: '${_currencySymbol ?? '₦'} ',
              prefixStyle: AlongType.title(p),
              border: AlongCraft.input(BorderSide.none),
              enabledBorder: AlongCraft.input(BorderSide.none),
              focusedBorder: AlongCraft.input(BorderSide(color: p.ink)),
            ),
          ),
          DriveSection(l10n.settleMethodTitle),
          DriveRows(
            children: [
              for (final c in channels)
                DriveRow(
                  key: c.$2,
                  icon: c.$5,
                  title: c.$3,
                  detail: c.$4,
                  selected: _channel == c.$1,
                  onTap: _busy ? null : () => setState(() => _channel = c.$1),
                ),
            ],
          ),
          if (_agentCode != null) ...[
            DriveSection(l10n.settleAgentCodeTitle),
            DriveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _agentCode!,
                    key: const Key('settle_agent_code'),
                    style: AlongType.display(p).copyWith(
                      fontSize: 40,
                      letterSpacing: 4,
                      fontFeatures: AlongType.figures,
                    ),
                  ),
                  if (_agentExpiresAt != null)
                    Text(
                      l10n.settleAgentExpires(_agentExpiresAt!),
                      style: AlongType.caption(p),
                    ),
                ],
              ),
            ),
            if (_nearbyAgents.isNotEmpty) ...[
              DriveSection(l10n.settleNearbyAgentsTitle),
              DriveRows(
                children: [
                  for (final agent in _nearbyAgents)
                    DriveRow(
                      key: Key('settle_nearby_agent_${agent.id}'),
                      icon: AlongIcons.mapPin,
                      title: agent.businessName,
                      trailing: l10n.settleNearbyAgentDistance(agent.distanceM),
                      trailingStyle: AlongType.caption(p),
                    ),
                ],
              ),
            ],
          ],
          if (_channelDetail != null) ...[
            const SizedBox(height: AlongSpace.s16),
            DrivePanel(
              child: SelectableText(_channelDetail!, style: AlongType.body(p)),
            ),
          ],
          if (_statusMessage != null) ...[
            const SizedBox(height: AlongSpace.s16),
            Text(
              _statusMessage!,
              key: const Key('settle_status_message'),
              style: AlongType.body(p).copyWith(
                fontWeight: FontWeight.w600,
                color: _activeSettlementId != null
                    ? AlongColors.semanticSuccess
                    : p.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
