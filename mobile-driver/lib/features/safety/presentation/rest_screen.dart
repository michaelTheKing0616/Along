import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

final restPrefsProvider = FutureProvider<RestPrefs>((ref) {
  return PhaseDStore(ref.watch(alongDatabaseProvider)).readRest();
});

final driveStartedProvider = FutureProvider<DateTime?>((ref) {
  return PhaseDStore(ref.watch(alongDatabaseProvider)).readDriveStarted();
});

/// The driver writes how long they drive and how long a rest must last.
class RestScreen extends ConsumerStatefulWidget {
  const RestScreen({super.key});

  @override
  ConsumerState<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends ConsumerState<RestScreen> {
  final _drive = TextEditingController();
  final _rest = TextEditingController();
  DateTime? _restingSince;
  var _priority = false;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final store = PhaseDStore(ref.read(alongDatabaseProvider));
    final prefs = await store.readRest();
    if (!mounted) return;
    setState(() {
      _drive.text = prefs.driveMinutes?.toString() ?? '';
      _rest.text = prefs.restMinutes?.toString() ?? '';
      _ready = true;
    });
  }

  @override
  void dispose() {
    _drive.dispose();
    _rest.dispose();
    super.dispose();
  }

  RestPrefs get _prefs => RestPrefs(
    driveMinutes: int.tryParse(_drive.text.trim()),
    restMinutes: int.tryParse(_rest.text.trim()),
  );

  Future<void> _save() async {
    final prefs = _prefs;
    final store = PhaseDStore(ref.read(alongDatabaseProvider));
    await store.writeRest(prefs);
    final repo = RobustnessRepository(
      ref.read(alongSupabaseProvider),
      queue: PendingActionQueue(ref.read(alongDatabaseProvider)),
    );
    try {
      await repo.saveRestPrefs(prefs, idempotencyKey: 'rest-prefs');
    } catch (_) {}
    ref.invalidate(restPrefsProvider);
  }

  Future<void> _startRest() async {
    setState(() => _restingSince = DateTime.now().toUtc());
  }

  Future<void> _endRest() async {
    final started = _restingSince;
    if (started == null) return;
    final ended = DateTime.now().toUtc();
    final qualified = restQualifies(
      rested: ended.difference(started),
      restMinutes: _prefs.restMinutes,
    );
    final repo = RobustnessRepository(
      ref.read(alongSupabaseProvider),
      queue: PendingActionQueue(ref.read(alongDatabaseProvider)),
    );
    try {
      await repo.recordDriverRest(
        startedAt: started,
        endedAt: ended,
        idempotencyKey: 'rest-${started.millisecondsSinceEpoch}',
      );
    } catch (_) {}
    final store = PhaseDStore(ref.read(alongDatabaseProvider));
    await store.writeDriveStarted(DateTime.now().toUtc());
    if (!mounted) return;
    setState(() {
      _restingSince = null;
      _priority = qualified;
    });
    ref.invalidate(driveStartedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    if (!_ready) {
      return DrivePage(
        title: l10n.restTitle,
        children: const [
          SizedBox(height: AlongSpace.s16),
          AlongSkeleton(variant: SkeletonVariant.line),
        ],
      );
    }
    final prefs = _prefs;
    final since = _restingSince;
    return DrivePage(
      title: l10n.restTitle,
      subtitle: l10n.restSubtitle,
      footer: since == null
          ? AlongButton(
              key: const Key('rest_begin'),
              label: l10n.restStart,
              onPressed: _startRest,
            )
          : AlongButton(
              key: const Key('rest_finish'),
              label: l10n.restFinish,
              onPressed: _endRest,
            ),
      children: [
        const SizedBox(height: AlongSpace.s16),
        DriveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DriveTag(
                label: since == null
                    ? l10n.restStatusDriving
                    : l10n.restStatusResting(
                        TimeOfDay.fromDateTime(since.toLocal()).format(context),
                      ),
                tone: since == null ? DriveTagTone.neutral : DriveTagTone.info,
              ),
              const SizedBox(height: AlongSpace.s12),
              Text(
                prefs.driveMinutes != null && prefs.restMinutes != null
                    ? l10n.restPlan(prefs.restMinutes!, prefs.driveMinutes!)
                    : l10n.restPlanEmpty,
                style: AlongType.title(p),
              ),
              if (_priority) ...[
                const SizedBox(height: AlongSpace.s8),
                Text(
                  l10n.restPriority,
                  key: const Key('rest_priority_label'),
                  style: AlongType.label(p).copyWith(color: p.success),
                ),
              ],
            ],
          ),
        ),
        DriveSection(l10n.restRhythmSection),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('rest_drive_minutes'),
                controller: _drive,
                keyboardType: TextInputType.number,
                decoration: driveInput(context, l10n.restDriveShort),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: AlongSpace.s8),
            Expanded(
              child: TextField(
                key: const Key('rest_minutes'),
                controller: _rest,
                keyboardType: TextInputType.number,
                decoration: driveInput(context, l10n.restBreakShort),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: AlongSpace.s8),
        AlongButton(
          key: const Key('rest_save'),
          label: l10n.restSave,
          variant: AlongButtonVariant.secondary,
          onPressed: _save,
        ),
      ],
    );
  }
}
