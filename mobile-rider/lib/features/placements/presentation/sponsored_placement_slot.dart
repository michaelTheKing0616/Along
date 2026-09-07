import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/placements/presentation/placement_providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Config-gated sponsored placement card labelled per l10n (P8-B-01, FM39).
class SponsoredPlacementSlot extends ConsumerStatefulWidget {
  const SponsoredPlacementSlot({
    super.key,
    required this.placements,
  });

  final List<SponsoredPlacement> placements;

  @override
  ConsumerState<SponsoredPlacementSlot> createState() =>
      _SponsoredPlacementSlotState();
}

class _SponsoredPlacementSlotState extends ConsumerState<SponsoredPlacementSlot> {
  final Set<String> _impressionRecorded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordImpressions());
  }

  @override
  void didUpdateWidget(covariant SponsoredPlacementSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placements != widget.placements) {
      _recordImpressions();
    }
  }

  Future<void> _recordImpressions() async {
    if (widget.placements.isEmpty) return;
    final repo = ref.read(placementsRepositoryProvider);
    for (final placement in widget.placements) {
      if (_impressionRecorded.contains(placement.id)) continue;
      _impressionRecorded.add(placement.id);
      try {
        await repo.recordImpression(placement.id);
      } catch (_) {}
    }
  }

  Future<void> _onTap(SponsoredPlacement placement) async {
    try {
      await ref.read(placementsRepositoryProvider).recordTap(placement.id);
    } catch (_) {}
    final url = placement.ctaUrl;
    if (url != null && url.isNotEmpty && mounted) {
      // Deep-link handling arrives later; tap is counted aggregate-only.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.placements.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final placement = widget.placements.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: AlongSpace.s12),
      child: Material(
        key: const Key('sponsored_placement_slot'),
        color: AlongColors.surface100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AlongRadius.md.x),
          side: const BorderSide(color: AlongColors.brandYellow, width: 1),
        ),
        child: InkWell(
          onTap: () => _onTap(placement),
          borderRadius: BorderRadius.circular(AlongRadius.md.x),
          child: Padding(
            padding: const EdgeInsets.all(AlongSpace.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sponsoredLabel,
                  style: AlongText.caption.copyWith(color: AlongColors.ink500),
                ),
                if (placement.headline != null) ...[
                  const SizedBox(height: AlongSpace.s4),
                  Text(
                    placement.headline!,
                    style: AlongText.bodyStrong.copyWith(color: AlongColors.ink900),
                  ),
                ],
                if (placement.body != null) ...[
                  const SizedBox(height: AlongSpace.s4),
                  Text(
                    placement.body!,
                    style: AlongText.body.copyWith(color: AlongColors.ink700),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
