import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// Second-phone seat board. The code is the only credential, and it expires.
class ConductorScreen extends ConsumerStatefulWidget {
  const ConductorScreen({super.key});

  @override
  ConsumerState<ConductorScreen> createState() => _ConductorScreenState();
}

class _ConductorScreenState extends ConsumerState<ConductorScreen> {
  final _code = TextEditingController();
  SeatBoard? _board;
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      final board = await ref
          .read(seatRepositoryProvider)
          .conductorBoard(_code.text.trim());
      if (!mounted) return;
      setState(() {
        _board = board;
        _error = null;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is AlongException ? error.code.apiValue : 'error';
      });
    }
  }

  Future<void> _set(String seatId, String status) async {
    final board = _board;
    if (board == null) return;
    await ref
        .read(seatRepositoryProvider)
        .conductorSetSeat(
          code: _code.text.trim(),
          seatId: seatId,
          status: status,
        );
    await _join();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final board = _board;
    final p = AlongPalette.of(context);
    return DrivePage(
      title: l10n.conductorTitle,
      subtitle: board == null
          ? l10n.conductorSubtitle
          : l10n.seatBoardSubtitle(board.freeCount),
      footer: board == null
          ? AlongButton(
              key: const Key('conductor_join_button'),
              label: l10n.conductorJoin,
              visualState: _busy
                  ? AlongButtonVisualState.loading
                  : AlongButtonVisualState.normal,
              onPressed: _busy ? null : _join,
            )
          : null,
      children: [
        const SizedBox(height: AlongSpace.s16),
        if (board == null)
          DriveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.conductorCode, style: AlongType.label(p)),
                const SizedBox(height: AlongSpace.s8),
                TextField(
                  key: const Key('conductor_code_field'),
                  controller: _code,
                  textAlign: TextAlign.center,
                  style: AlongType.title(p).copyWith(letterSpacing: 4),
                  decoration: driveInput(
                    context,
                    '',
                  ).copyWith(labelText: null, hintText: '— — — — — —'),
                ),
                const SizedBox(height: AlongSpace.s12),
                Text(l10n.conductorHowTo, style: AlongType.bodyMuted(p)),
              ],
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: AlongSpace.s12),
          Text(_error!, style: AlongType.caption(p).copyWith(color: p.danger)),
        ],
        if (board != null)
          SeatMap(
            body: board.layout.body,
            rows: [
              for (final row in board.layout.rows)
                SeatMapRowView(
                  id: row.id,
                  seats: [
                    for (final seat in row.seats)
                      SeatMapSeat(
                        id: seat.id,
                        label: seat.label,
                        role: seat.role,
                        status: _status(board, seat.id),
                        statusWord: seat.isCargo
                            ? l10n.seatLuggage
                            : seat.isPassenger
                            ? _status(board, seat.id)
                            : l10n.seatDriver,
                      ),
                  ],
                ),
            ],
            onSeatTap: (id) {
              final status = _status(board, id);
              _set(id, status == 'free' ? 'occupied' : 'free');
            },
          ),
      ],
    );
  }

  String _status(SeatBoard board, String seatId) {
    for (final seat in board.seats) {
      if (seat.seatId == seatId) return seat.status;
    }
    return 'free';
  }
}
