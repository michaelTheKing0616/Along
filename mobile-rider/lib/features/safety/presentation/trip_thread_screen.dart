import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

class TripThreadArgs {
  const TripThreadArgs({required this.tripId, required this.endedAt});

  final String tripId;
  final DateTime endedAt;
}

/// Masked notes with the other person for 48 hours after the trip ends.
class TripThreadScreen extends ConsumerStatefulWidget {
  const TripThreadScreen({super.key, required this.args});

  final TripThreadArgs args;

  @override
  ConsumerState<TripThreadScreen> createState() => _TripThreadScreenState();
}

class _TripThreadScreenState extends ConsumerState<TripThreadScreen> {
  final _body = TextEditingController();
  var _messages = const <TripMessage>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  bool get _open =>
      tripMessageWindowOpen(endedAt: widget.args.endedAt, now: DateTime.now());

  Future<void> _load() async {
    try {
      final rows = await RobustnessRepository(ref.read(alongSupabaseProvider))
          .listTripMessages(widget.args.tripId);
      if (mounted) setState(() => _messages = rows);
    } catch (_) {
      if (mounted) setState(() => _messages = const []);
    }
  }

  Future<void> _send() async {
    final text = _body.text.trim();
    if (text.isEmpty || !_open) return;
    final refId = 'msg-${DateTime.now().microsecondsSinceEpoch}';
    final repo = RobustnessRepository(
      ref.read(alongSupabaseProvider),
      queue: PendingActionQueue(ref.read(alongDatabaseProvider)),
    );
    try {
      await repo.postTripMessage(
        tripId: widget.args.tripId,
        body: text,
        clientRef: refId,
      );
    } catch (_) {}
    _body.clear();
    setState(() {
      _messages = [
        ..._messages,
        TripMessage(
          id: refId,
          authorRole: 'rider',
          body: text,
          createdAt: DateTime.now(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripMessagesTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AlongSpace.s16),
              children: [
                if (!_open)
                  Text(l10n.tripMessagesClosed, style: AlongText.body),
                for (final message in _messages)
                  MaskedMessageLine(
                    roleLabel: message.authorRole == 'driver'
                        ? l10n.tripMessagesDriver
                        : l10n.tripMessagesRider,
                    body: message.body,
                  ),
              ],
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.all(AlongSpace.s16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('trip_message_field'),
                      controller: _body,
                      decoration: InputDecoration(
                        hintText: l10n.tripMessagesHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: AlongSpace.s8),
                  AlongButton(
                    key: const Key('trip_message_send'),
                    label: l10n.tripMessagesSend,
                    fullWidth: false,
                    onPressed: _send,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
