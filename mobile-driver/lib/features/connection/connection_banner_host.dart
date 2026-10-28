import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// Reachability signal; tests override with [FakeConnectionSource].
final connectionSourceProvider = Provider<ConnectionSource>(
  (ref) => ConnectivityConnectionSource(),
);

final connectionControllerProvider = Provider<ConnectionController>((ref) {
  final queue = PendingActionQueue(ref.watch(alongDatabaseProvider));
  Future<int> count() async => (await queue.pendingFifo()).length;
  final controller = ConnectionController(
    source: ref.watch(connectionSourceProvider),
    queuedCount: count,
    replay: () async {
      final pending = await queue.pendingFifo();
      // Only the SOS outbox replays from here; other features flush their
      // own actions, so never touch a queue that holds anything else.
      if (pending.isEmpty ||
          pending.any((a) => a.type != SosOutbox.actionType)) {
        return 0;
      }
      await ref
          .read(sosOutboxProvider)
          .flush(ref.read(safetyRepositoryProvider));
      return pending.length - await count();
    },
  );
  controller.start();
  ref.onDispose(controller.dispose);
  return controller;
});

final connectionSnapshotProvider = StreamProvider<ConnectionSnapshot>((ref) {
  final controller = ref.watch(connectionControllerProvider);
  return controller.changes;
});

/// Shows the offline / reconnecting / back-online banner over every route.
class ConnectionBannerHost extends ConsumerWidget {
  const ConnectionBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(connectionControllerProvider);
    final snap =
        ref.watch(connectionSnapshotProvider).valueOrNull ?? controller.current;
    final l10n = AppLocalizations.of(context);
    final banner = switch (snap.phase) {
      ConnectionPhase.online => null,
      ConnectionPhase.offline => AlongConnectionBanner(
        key: const Key('connection_banner_offline'),
        tone: AlongConnectionTone.offline,
        label: snap.queued > 0
            ? l10n.connOfflineQueued(snap.queued)
            : l10n.connOffline,
        actionLabel: l10n.connRetry,
        onAction: controller.retry,
      ),
      ConnectionPhase.reconnecting => AlongConnectionBanner(
        key: const Key('connection_banner_reconnecting'),
        tone: AlongConnectionTone.reconnecting,
        label: snap.queued > 0
            ? l10n.connSending(snap.queued)
            : l10n.connReconnecting,
      ),
      ConnectionPhase.restored => AlongConnectionBanner(
        key: const Key('connection_banner_restored'),
        tone: AlongConnectionTone.restored,
        label: snap.sent > 0
            ? l10n.connRestoredSent(snap.sent)
            : l10n.connRestored,
      ),
    };
    return AlongConnectionHost(banner: banner, child: child);
  }
}
