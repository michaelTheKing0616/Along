import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Reachability signal; tests override with [FakeConnectionSource].
final connectionSourceProvider = Provider<ConnectionSource>(
  (ref) => ConnectivityConnectionSource(),
);

final connectionControllerProvider = Provider<ConnectionController>((ref) {
  final replayer = QueuedActionReplayer(
    queue: PendingActionQueue(ref.watch(alongDatabaseProvider)),
    gateway: ref.watch(alongSupabaseProvider),
    safety: ref.watch(safetyRepositoryProvider),
  );
  final controller = ConnectionController(
    source: ref.watch(connectionSourceProvider),
    queuedCount: () async => (await replayer.summary()).sendsWhenOnline,
    needsConnectionCount: () async =>
        (await replayer.summary()).needsConnection,
    replay: replayer.replay,
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
        label: _offlineLabel(l10n, snap),
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

  static String _offlineLabel(AppLocalizations l10n, ConnectionSnapshot snap) {
    if (snap.queued > 0 && snap.needsConnection > 0) {
      return l10n.connOfflineMixed(snap.queued, snap.needsConnection);
    }
    if (snap.queued > 0) return l10n.connOfflineQueued(snap.queued);
    if (snap.needsConnection > 0) {
      return l10n.connNeedsConnection(snap.needsConnection);
    }
    return l10n.connOffline;
  }
}
