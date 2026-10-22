import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';
import 'package:mobile_driver/features/ledger/presentation/ledger_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

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
      final meta =
          await ref.read(catalogRepositoryProvider).currencyMetaForCity(cityId);
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
    if (ledger.balance.amount <= Decimal.zero) {
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
      final currency = ref.read(driverLedgerControllerProvider).balance.currency;
      final amount = _parseAmount(currency);
      if (amount.amount <= Decimal.zero) {
        setState(
          () => _statusMessage = 'Enter at least ${_formatMinimumAmount(currency)}',
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
      setState(() => _statusMessage = 'Could not start settlement — try another channel');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPolling(String settlementId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final snapshot =
          await ref.read(ledgerRepositoryProvider).settlementStatus(settlementId);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledger = ref.watch(driverLedgerControllerProvider);

    return Scaffold(
      key: const Key('settle_screen'),
      appBar: AppBar(
        title: Text(l10n.settleTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AlongSpace.s16),
        children: [
          Text(
            l10n.settleCurrentBalance(
              formatMoney(
                ledger.balance,
                currencySymbol: _currencySymbol,
              ),
            ),
            style: AlongText.body,
          ),
          const SizedBox(height: AlongSpace.s16),
          TextField(
            key: const Key('settle_amount_field'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.settleAmountLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AlongSpace.s16),
          AlongButton(
            key: const Key('settle_bank'),
            label: l10n.settleChannelBank,
            variant: AlongButtonVariant.secondary,
            visualState:
                _busy ? AlongButtonVisualState.loading : AlongButtonVisualState.normal,
            onPressed: _busy ? null : () => _initiateChannel('paystack_transfer'),
          ),
          const SizedBox(height: AlongSpace.s8),
          AlongButton(
            key: const Key('settle_ussd'),
            label: l10n.settleChannelUssd,
            variant: AlongButtonVariant.secondary,
            onPressed: _busy ? null : () => _initiateChannel('paystack_ussd'),
          ),
          const SizedBox(height: AlongSpace.s8),
          AlongButton(
            key: const Key('settle_card'),
            label: l10n.settleChannelCard,
            variant: AlongButtonVariant.secondary,
            onPressed: _busy ? null : () => _initiateChannel('paystack_card'),
          ),
          const SizedBox(height: AlongSpace.s8),
          AlongButton(
            key: const Key('settle_agent'),
            label: l10n.settleChannelAgent,
            variant: AlongButtonVariant.yellow,
            onPressed: _busy ? null : () => _initiateChannel('agent'),
          ),
          if (_agentCode != null) ...[
            const SizedBox(height: AlongSpace.s24),
            Text(l10n.settleAgentCodeTitle, style: AlongText.heading2),
            Text(
              _agentCode!,
              key: const Key('settle_agent_code'),
              style: AlongText.displayL,
            ),
            if (_agentExpiresAt != null)
              Text(
                l10n.settleAgentExpires(_agentExpiresAt!),
                style: AlongText.caption.copyWith(color: AlongColors.ink500),
              ),
            if (_nearbyAgents.isNotEmpty) ...[
              const SizedBox(height: AlongSpace.s16),
              Text(l10n.settleNearbyAgentsTitle, style: AlongText.bodyStrong),
              const SizedBox(height: AlongSpace.s8),
              ..._nearbyAgents.map(
                (agent) => ListTile(
                  key: Key('settle_nearby_agent_${agent.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(agent.businessName, style: AlongText.bodyStrong),
                  trailing: Text(
                    l10n.settleNearbyAgentDistance(agent.distanceM),
                    style: AlongText.caption.copyWith(color: AlongColors.ink500),
                  ),
                ),
              ),
            ],
          ],
          if (_channelDetail != null) ...[
            const SizedBox(height: AlongSpace.s16),
            Text(_channelDetail!, style: AlongText.body),
          ],
          if (_statusMessage != null) ...[
            const SizedBox(height: AlongSpace.s16),
            Text(
              _statusMessage!,
              key: const Key('settle_status_message'),
              style: AlongText.bodyStrong.copyWith(
                color: _activeSettlementId != null
                    ? AlongColors.semanticSuccess
                    : AlongColors.ink700,
              ),
            ),
          ],
          const SizedBox(height: AlongSpace.s16),
          AlongButton(
            label: l10n.settleDone,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
