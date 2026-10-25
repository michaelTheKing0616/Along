import 'dart:async';

import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';

const _role = 'driver';

/// Overridden at startup with the Supabase private channel; tests and
/// previews use the in-memory one.
final tripChatChannelFactoryProvider = Provider<TripChatChannel Function()>(
  (ref) => InMemoryTripChatChannel.new,
);

/// Live trip chat. Watched by the trip screen for the whole live trip, so
/// the thread is loaded before the Message button is tapped.
final tripChatProvider = ChangeNotifierProvider.autoDispose
    .family<TripChatController, String>((ref, tripId) {
      final chat = TripChatController(
        gateway: ref.watch(alongSupabaseProvider),
        channel: ref.watch(tripChatChannelFactoryProvider)(),
        tripId: tripId,
        myRole: _role,
      );
      unawaited(chat.start());
      return chat;
    });

final tripChatQuickRepliesProvider = FutureProvider<List<String>>((ref) async {
  Object? raw;
  try {
    raw = await ref
        .watch(configRepositoryProvider)
        .configJson('chat.quick_replies');
  } catch (_) {}
  return tripChatQuickReplies(raw, _role);
});

AlongChatLine _line(TripChatEntry e) => AlongChatLine(
  id: e.key,
  body: e.body,
  mine: e.mine,
  at: e.at,
  status: switch (e.state) {
    TripChatState.sending => AlongChatStatus.sending,
    TripChatState.sent => AlongChatStatus.sent,
    TripChatState.read => AlongChatStatus.read,
    TripChatState.failed => AlongChatStatus.failed,
  },
);

Future<void> openTripChat(
  BuildContext context,
  WidgetRef ref, {
  required String tripId,
  required String otherName,
}) {
  final chat = ref.read(tripChatProvider(tripId));
  chat.visible = true;
  return showAlongTripChat(
    context,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final chat = ref.watch(tripChatProvider(tripId));
        final replies =
            ref.watch(tripChatQuickRepliesProvider).valueOrNull ??
            tripChatQuickReplies(null, _role);
        return AlongTripChatSheet(
          otherName: otherName,
          lines: [for (final e in chat.lines) _line(e)],
          quickReplies: replies,
          onSend: chat.send,
          onRetry: chat.retry,
          closed: chat.closed,
        );
      },
    ),
  ).whenComplete(() => chat.visible = false);
}
