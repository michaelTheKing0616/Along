import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import '../craft.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';

/// Where one chat line is on its way to the other phone.
enum AlongChatStatus { sending, sent, read, failed }

class AlongChatLine {
  const AlongChatLine({
    required this.id,
    required this.body,
    required this.mine,
    required this.at,
    this.status = AlongChatStatus.sent,
  });

  final String id;
  final String body;
  final bool mine;
  final DateTime at;
  final AlongChatStatus status;
}

/// Opens [AlongTripChatSheet] on a 32-radius sheet. The route animates on
/// [AlongMoves.arrive]; the chat itself is already loaded (preloaded at
/// handoff), so the first frame shows the thread.
Future<void> showAlongTripChat(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final p = AlongPalette.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: p.bg,
    shape: AlongCraft.borderVertical(top: 32),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: AnimationStyle(
      duration: AlongMoves.arrive.of(context),
      reverseDuration: AlongMoves.select.of(context),
    ),
    builder: builder,
  );
}

/// R/D trip chat. One tap on a quick reply sends it; free text sends on
/// the arrow or the keyboard's send key. Lines appear instantly and tick
/// from sending to sent to read; a failed line retries on tap.
class AlongTripChatSheet extends StatefulWidget {
  const AlongTripChatSheet({
    super.key,
    required this.otherName,
    required this.lines,
    required this.quickReplies,
    required this.onSend,
    this.onRetry,
    this.onClose,
    this.closed = false,
    this.maxLength = 280,
  });

  final String otherName;
  final List<AlongChatLine> lines;
  final List<String> quickReplies;
  final ValueChanged<String> onSend;
  final ValueChanged<String>? onRetry;
  final VoidCallback? onClose;

  /// Trip over and the chat window shut: thread stays readable.
  final bool closed;
  final int maxLength;

  @override
  State<AlongTripChatSheet> createState() => _AlongTripChatSheetState();
}

class _AlongTripChatSheetState extends State<AlongTripChatSheet> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send(String body) {
    final value = body.trim();
    if (value.isEmpty || widget.closed) return;
    AlongHaptics.tick(context);
    widget.onSend(value);
  }

  void _sendTyped() {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    _send(value);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final media = MediaQuery.of(context);
    final soft = p.ink.withValues(alpha: 0.72);
    final lines = widget.lines;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.78),
        child: Column(
          key: const Key('trip_chat'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: ShapeDecoration(
                    color: p.ink.withValues(alpha: 0.18),
                    shape: AlongCraft.border(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.title(p),
                    ),
                  ),
                  _SquareButton(
                    key: const Key('trip_chat_close'),
                    label: 'Close',
                    icon: AlongIcons.close,
                    onTap: widget.onClose ?? () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: lines.isEmpty
                  ? _Empty(closed: widget.closed)
                  : ListView.builder(
                      key: const Key('trip_chat_list'),
                      reverse: true,
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: lines.length,
                      itemBuilder: (context, i) {
                        final line = lines[lines.length - 1 - i];
                        final lastMine =
                            line.mine &&
                            lines.lastIndexWhere((l) => l.mine) ==
                                lines.length - 1 - i;
                        return _Bubble(
                          line: line,
                          showStatus:
                              lastMine || line.status == AlongChatStatus.failed,
                          onRetry: widget.onRetry,
                        );
                      },
                    ),
            ),
            if (widget.closed && lines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Text(
                  'This trip has ended. Chat is closed.',
                  style: AlongType.label(p).copyWith(color: soft),
                ),
              )
            else ...[
              Padding(
                key: const Key('trip_chat_quick_replies'),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < widget.quickReplies.length; i++)
                      _QuickReply(
                        key: Key('trip_chat_quick_$i'),
                        label: widget.quickReplies[i],
                        primary: lines.isEmpty && i < 2,
                        onTap: () => _send(widget.quickReplies[i]),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  6,
                  16,
                  12 + (media.viewInsets.bottom > 0 ? 0 : media.padding.bottom),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('trip_chat_input'),
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: widget.maxLength,
                        textInputAction: TextInputAction.send,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendTyped(),
                        style: AlongType.body(p),
                        decoration: InputDecoration(
                          hintText: 'Message ${widget.otherName}',
                          hintStyle: AlongType.body(p).copyWith(color: soft),
                          counterText: '',
                          filled: true,
                          fillColor: p.surface,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: AlongCraft.input(BorderSide(color: p.line)),
                          enabledBorder: AlongCraft.input(
                            BorderSide(color: p.line),
                          ),
                          focusedBorder: AlongCraft.input(
                            BorderSide(color: p.ink, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SquareButton(
                      key: const Key('trip_chat_send'),
                      label: 'Send',
                      icon: AlongIcons.send,
                      filled: _text.text.trim().isNotEmpty,
                      onTap: _text.text.trim().isEmpty ? null : _sendTyped,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.line, required this.showStatus, this.onRetry});

  final AlongChatLine line;
  final bool showStatus;
  final ValueChanged<String>? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final mine = line.mine;
    final failed = line.status == AlongChatStatus.failed;
    final bubble = Container(
      constraints: BoxConstraints(
        minHeight: 44,
        maxWidth: MediaQuery.sizeOf(context).width * 0.74,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: ShapeDecoration(
        color: mine ? p.ink : p.surface,
        shape: SmoothRectangleBorder(
          side: mine ? BorderSide.none : BorderSide(color: p.line),
          borderRadius: SmoothBorderRadius.only(
            topLeft: _corner(20),
            topRight: _corner(20),
            bottomLeft: _corner(mine ? 20 : 6),
            bottomRight: _corner(mine ? 6 : 20),
          ),
        ),
      ),
      child: Text(
        line.body,
        style: AlongType.body(p).copyWith(color: mine ? p.onInk : p.ink),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          AnimatedOpacity(
            opacity: line.status == AlongChatStatus.sending ? 0.72 : 1,
            duration: AlongMoves.select.of(context),
            child: failed && onRetry != null
                ? GestureDetector(
                    key: Key('trip_chat_retry_${line.id}'),
                    onTap: () => onRetry!(line.id),
                    child: bubble,
                  )
                : bubble,
          ),
          if (showStatus && mine) _Status(line: line),
        ],
      ),
    );
  }
}

SmoothRadius _corner(double r) =>
    SmoothRadius(cornerRadius: r, cornerSmoothing: AlongCraft.smoothing);

class _Status extends StatelessWidget {
  const _Status({required this.line});

  final AlongChatLine line;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final soft = p.ink.withValues(alpha: 0.86);
    final (IconData icon, String label, Color color) = switch (line.status) {
      AlongChatStatus.sending => (AlongIcons.schedule, 'Sending', soft),
      AlongChatStatus.sent => (AlongIcons.check, 'Delivered', soft),
      AlongChatStatus.read => (AlongIcons.checks, 'Read', p.success),
      AlongChatStatus.failed => (
        AlongIcons.info,
        'Not sent. Tap to retry.',
        p.danger,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 4),
      child: Row(
        key: Key('trip_chat_status_${line.status.name}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          AlongIcon(icon, size: 16, color: color, tone: false),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AlongType.caption(p)
                  .copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReply extends StatelessWidget {
  const _QuickReply({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;

  /// First replies in an empty thread: filled so the first tap is obvious.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Material(
      color: primary ? p.ink : p.surface,
      shape: AlongCraft.border(
        16,
        side: primary ? BorderSide.none : BorderSide(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AlongType.label(p).copyWith(
                  fontWeight: FontWeight.w600,
                  color: primary ? p.onInk : p.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.closed});

  final bool closed;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Padding(
      key: const Key('trip_chat_empty'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: AlongCraft.fill(
              p.surface,
              corner: 16,
              side: BorderSide(color: p.line),
            ),
            child: AlongIcon(AlongIcons.chat, size: 28, color: p.ink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  closed ? 'Chat is closed' : 'Say hi, one tap below',
                  style: AlongType.title(p),
                ),
                const SizedBox(height: 4),
                Text(
                  closed
                      ? 'This trip has ended.'
                      : 'Your number stays private.',
                  style: AlongType.body(p)
                      .copyWith(color: p.ink.withValues(alpha: 0.72)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AlongMoves.select.of(context),
        curve: AlongMoves.select.curve,
        decoration: AlongCraft.fill(filled ? p.ink : p.surface, corner: 16),
        child: Material(
          type: MaterialType.transparency,
          shape: AlongCraft.border(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: AlongIcon(
                  icon,
                  size: 22,
                  color: filled ? p.onInk : p.ink,
                  tone: icon != AlongIcons.close,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
