import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

final guardianPrefsProvider = FutureProvider<GuardianPrefs>((ref) {
  return PhaseDStore(ref.watch(alongDatabaseProvider)).readGuardian();
});

/// Rider-authored Guardian thresholds. Blank numbers leave that check off.
class GuardianScreen extends ConsumerStatefulWidget {
  const GuardianScreen({super.key});

  @override
  ConsumerState<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends ConsumerState<GuardianScreen> {
  final _offRoute = TextEditingController();
  final _longStop = TextEditingController();
  final _checkIn = TextEditingController();
  final _word = TextEditingController();
  var _enabled = false;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final prefs = await PhaseDStore(ref.read(alongDatabaseProvider))
        .readGuardian();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.enabled;
      _offRoute.text = prefs.offRouteMeters?.toString() ?? '';
      _longStop.text = prefs.longStopMinutes?.toString() ?? '';
      _checkIn.text = prefs.checkInMinutes?.toString() ?? '';
      _word.text = prefs.safeWord;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _offRoute.dispose();
    _longStop.dispose();
    _checkIn.dispose();
    _word.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prefs = GuardianPrefs(
      enabled: _enabled,
      offRouteMeters: int.tryParse(_offRoute.text.trim()),
      longStopMinutes: int.tryParse(_longStop.text.trim()),
      checkInMinutes: int.tryParse(_checkIn.text.trim()),
      safeWord: _word.text.trim(),
    );
    final store = PhaseDStore(ref.read(alongDatabaseProvider));
    await store.writeGuardian(prefs);
    final repo = RobustnessRepository(
      ref.read(alongSupabaseProvider),
      queue: PendingActionQueue(ref.read(alongDatabaseProvider)),
    );
    try {
      await repo.saveGuardianPrefs(prefs, idempotencyKey: 'guardian-prefs');
    } catch (_) {
      // The phone already has the rules. The queue keeps the server copy.
    }
    ref.invalidate(guardianPrefsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guardianTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AlongSpace.s16),
        children: [
          SwitchListTile(
            key: const Key('guardian_enabled'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.guardianEnabled),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          TextField(
            key: const Key('guardian_off_route'),
            controller: _offRoute,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.guardianOffRoute),
          ),
          TextField(
            key: const Key('guardian_long_stop'),
            controller: _longStop,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.guardianLongStop),
          ),
          TextField(
            key: const Key('guardian_check_in'),
            controller: _checkIn,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.guardianCheckIn),
          ),
          TextField(
            key: const Key('guardian_safe_word'),
            controller: _word,
            decoration: InputDecoration(labelText: l10n.guardianSafeWord),
          ),
          const SizedBox(height: AlongSpace.s16),
          AlongButton(
            key: const Key('guardian_save'),
            label: l10n.guardianSave,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
