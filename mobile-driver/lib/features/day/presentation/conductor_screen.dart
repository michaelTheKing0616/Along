import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.conductorTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AlongSpace.s16),
        children: [
          TextField(
            key: const Key('conductor_code_field'),
            controller: _code,
            decoration: InputDecoration(labelText: l10n.conductorCode),
          ),
          const SizedBox(height: AlongSpace.s12),
          AlongButton(
            key: const Key('conductor_join_button'),
            label: l10n.conductorJoin,
            visualState: _busy
                ? AlongButtonVisualState.loading
                : AlongButtonVisualState.normal,
            onPressed: _busy ? null : _join,
          ),
          if (_error != null) ...[
            const SizedBox(height: AlongSpace.s12),
            Text(
              _error!,
              style: AlongText.caption.copyWith(
                color: AlongColors.semanticDanger,
              ),
            ),
          ],
          if (board != null) ...[
            const SizedBox(height: AlongSpace.s16),
            Text(
              l10n.freeSeatCount(board.freeCount),
              style: AlongText.bodyStrong,
            ),
            const SizedBox(height: AlongSpace.s12),
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
        ],
      ),
    );
  }

  String _status(SeatBoard board, String seatId) {
    for (final seat in board.seats) {
      if (seat.seatId == seatId) return seat.status;
    }
    return 'free';
  }
}
