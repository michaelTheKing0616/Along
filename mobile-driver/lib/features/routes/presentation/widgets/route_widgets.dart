import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

class RouteProfileCard extends StatelessWidget {
  const RouteProfileCard({
    super.key,
    required this.profile,
    required this.modeLabel,
    required this.onToggleActive,
    required this.onTap,
  });

  final DriverRouteProfileRow profile;
  final String modeLabel;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = profile.name ?? l10n.routeUnnamedProfile(modeLabel);

    return Card(
      child: InkWell(
        onTap: onTap,
        customBorder: AlongCraft.border(AlongRadius.card.x),
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: AlongText.title),
                  ),
                  Switch(
                    value: profile.active,
                    onChanged: profile.active ? onToggleActive : null,
                  ),
                ],
              ),
              const SizedBox(height: AlongSpace.s8),
              Text(
                l10n.routeStopsCount(profile.stops.length),
                style: AlongText.body.copyWith(color: AlongColors.ink500),
              ),
              if (profile.loadSurchargeAmount != null &&
                  profile.loadSurchargeAmount! > 0) ...[
                const SizedBox(height: AlongSpace.s4),
                Text(
                  l10n.routeLoadSurchargeLabel(
                    formatMoney(profile.loadSurchargeAmount!.round()),
                  ),
                  style: AlongText.caption,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SuggestedRouteCard extends StatelessWidget {
  const SuggestedRouteCard({
    super.key,
    required this.suggestion,
    required this.modeLabel,
    required this.onTap,
  });

  final SuggestedKnownRoute suggestion;
  final String modeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: AlongColors.brandYellow.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        customBorder: AlongCraft.border(AlongRadius.card.x),
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.routeSuggestedCardTitle,
                style: AlongText.title,
              ),
              const SizedBox(height: AlongSpace.s8),
              Text(
                l10n.routeSuggestedCardBody(
                  modeLabel,
                  suggestion.stages.length,
                ),
                style: AlongText.body,
              ),
              const SizedBox(height: AlongSpace.s12),
              Text(
                l10n.routeSuggestedCardCta,
                style: AlongText.label.copyWith(color: AlongColors.ink700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RouteStopRow extends StatelessWidget {
  const RouteStopRow({
    super.key,
    required this.index,
    required this.stop,
    required this.onPriceTap,
    this.onLabelChanged,
  });

  final int index;
  final dynamic stop;
  final VoidCallback onPriceTap;
  final ValueChanged<String>? onLabelChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = stop;
    final price = draft.priceToEnd as Decimal;
    final priceLabel = formatMoney(price.toBigInt().toInt());

    return Card(
      key: ValueKey('route_stop_${draft.sequence}'),
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s12),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle_rounded),
            ),
            const SizedBox(width: AlongSpace.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.displayName as String, style: AlongText.bodyStrong),
                  const SizedBox(height: AlongSpace.s4),
                  SnapStatusChip(
                    matchedName: draft.matchedStageName as String?,
                    isNewStop: draft.isNewStop as bool,
                    customLabel: draft.customLabel as String?,
                    onLabelChanged: onLabelChanged,
                  ),
                ],
              ),
            ),
            TextButton(
              key: Key('price_chip_${draft.sequence}'),
              onPressed: onPriceTap,
              child: Text(l10n.routePriceToEnd(priceLabel)),
            ),
          ],
        ),
      ),
    );
  }
}

class SnapStatusChip extends StatelessWidget {
  const SnapStatusChip({
    super.key,
    required this.matchedName,
    required this.isNewStop,
    this.customLabel,
    this.onLabelChanged,
  });

  final String? matchedName;
  final bool isNewStop;
  final String? customLabel;
  final ValueChanged<String>? onLabelChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (matchedName != null) {
      return Container(
        key: Key('snap_matched_$matchedName'),
        padding: const EdgeInsets.symmetric(
          horizontal: AlongSpace.s8,
          vertical: AlongSpace.s4,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: AlongCraft.fill(
          AlongColors.semanticSuccessTint,
          corner: AlongRadius.xs.x,
        ),
        child: Text(
          l10n.routeSnapMatched(matchedName!),
          style: AlongText.caption.copyWith(color: AlongColors.semanticSuccessFill),
        ),
      );
    }

    if (isNewStop) {
      return TextField(
        key: const Key('new_stop_label_field'),
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.routeSnapNewStopHint,
          border: AlongCraft.input(const BorderSide()),
        ),
        controller: TextEditingController(text: customLabel),
        onChanged: onLabelChanged,
      );
    }

    return Text(
      l10n.routeSnapPending,
      style: AlongText.caption.copyWith(color: AlongColors.ink500),
    );
  }
}

class RoutePriceErrorBanner extends StatelessWidget {
  const RoutePriceErrorBanner({super.key, required this.errorKey});

  final String errorKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (errorKey) {
      'routePriceErrorNonMonotone' => l10n.routePriceErrorNonMonotone,
      'routePriceErrorLastNotZero' => l10n.routePriceErrorLastNotZero,
      'routePriceErrorEmpty' => l10n.routePriceErrorEmpty,
      _ => l10n.errorGeneric,
    };

    return Container(
      key: Key('route_price_error_$errorKey'),
      width: double.infinity,
      padding: const EdgeInsets.all(AlongSpace.s12),
      clipBehavior: Clip.antiAlias,
      decoration: AlongCraft.fill(
        AlongColors.semanticDangerTint,
        corner: AlongRadius.row.x,
      ),
      child: Text(
        message,
        style: AlongText.body.copyWith(color: AlongColors.semanticDangerFill),
      ),
    );
  }
}

class LoadSurchargeField extends StatelessWidget {
  const LoadSurchargeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Decimal? value;
  final ValueChanged<Decimal?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextField(
      key: const Key('load_surcharge_field'),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: l10n.routeLoadSurchargeOptional,
        hintText: l10n.routeLoadSurchargeHint,
        border: AlongCraft.input(const BorderSide()),
      ),
      controller: TextEditingController(
        text: value == null ? '' : value!.toBigInt().toString(),
      ),
      onChanged: (raw) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) {
          onChanged(null);
          return;
        }
        final parsed = int.tryParse(trimmed);
        if (parsed == null || parsed < 0) return;
        onChanged(Decimal.fromInt(parsed));
      },
    );
  }
}
