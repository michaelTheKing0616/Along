import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Park loading board. The fullest car is the one leaving next.
class StageRadarScreen extends StatelessWidget {
  const StageRadarScreen({super.key, required this.rows, this.onFavourite});

  final List<StageVehicle> rows;
  final ValueChanged<String>? onFavourite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ordered = stageRadarOrder(rows);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.stageRadarTitle)),
      body: ordered.isEmpty
          ? Center(child: Text(l10n.stageRadarEmpty, style: AlongText.body))
          : ListView(
              padding: const EdgeInsets.all(AlongSpace.s16),
              children: [
                for (var i = 0; i < ordered.length; i++)
                  _StageRow(
                    vehicle: ordered[i],
                    leaving: i == 0,
                    leavingLabel: l10n.stageRadarLeaving,
                    seatsLabel: l10n.stageRadarSeats(
                      ordered[i].seatsFree,
                      ordered[i].seatsTotal,
                    ),
                    verifiedLabel: l10n.stageRadarVerified,
                    favouriteLabel: l10n.stageRadarFavourite,
                    onFavourite: onFavourite,
                  ),
              ],
            ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.vehicle,
    required this.leaving,
    required this.leavingLabel,
    required this.seatsLabel,
    required this.verifiedLabel,
    required this.favouriteLabel,
    this.onFavourite,
  });

  final StageVehicle vehicle;
  final bool leaving;
  final String leavingLabel;
  final String seatsLabel;
  final String verifiedLabel;
  final String favouriteLabel;
  final ValueChanged<String>? onFavourite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AlongSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leaving)
            Text(
              leavingLabel,
              key: const Key('stage_leaving_next'),
              style: AlongText.label.copyWith(
                color: AlongColors.semanticWarning,
              ),
            ),
          Text(vehicle.name, style: AlongText.bodyStrong),
          Text(vehicle.plate, style: AlongText.numericM),
          Text(
            seatsLabel,
            key: Key('stage_seats_${vehicle.driverId}'),
            style: AlongText.body,
          ),
          if (vehicle.verified) Text(verifiedLabel, style: AlongText.caption),
          if (onFavourite != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('stage_favourite_${vehicle.driverId}'),
                onPressed: () => onFavourite!(vehicle.driverId),
                child: Text(favouriteLabel),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loads the board for one park. A phone number is never on the row.
class StageRadarPage extends ConsumerStatefulWidget {
  const StageRadarPage({super.key, required this.parkId});

  final String parkId;

  @override
  ConsumerState<StageRadarPage> createState() => _StageRadarPageState();
}

class _StageRadarPageState extends ConsumerState<StageRadarPage> {
  var _rows = const <StageVehicle>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final raw = await ref
          .read(alongSupabaseProvider)
          .rpc('stage_board', params: {'p_park_id': widget.parkId});
      if (!mounted || raw is! List) return;
      setState(() {
        _rows = [
          for (final row in raw)
            if (row is Map) _vehicle(Map<String, dynamic>.from(row)),
        ];
      });
    } catch (_) {
      if (mounted) setState(() => _rows = const []);
    }
  }

  StageVehicle _vehicle(Map<String, dynamic> row) {
    return StageVehicle(
      driverId: row['driver_id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      plate: row['plate'] as String? ?? '',
      seatsFree: (row['seats_free'] as num?)?.toInt() ?? 0,
      seatsTotal: (row['seats_total'] as num?)?.toInt() ?? 0,
      startedAt:
          DateTime.tryParse(row['started_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      verified: row['verified'] as bool? ?? false,
    );
  }

  Future<void> _favourite(String driverId) async {
    try {
      await ref
          .read(alongSupabaseProvider)
          .rpc(
            'save_favourite',
            params: {'p_driver_id': driverId, 'p_on': true},
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StageRadarScreen(rows: _rows, onFavourite: _favourite);
  }
}
