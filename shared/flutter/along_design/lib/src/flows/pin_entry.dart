import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/along_button.dart';
import '../craft.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';

/// What the server said about one PIN attempt.
enum AlongPinVerdict { verified, wrong, rateLimited, locked, failed }

class AlongPinResult {
  const AlongPinResult(this.verdict, {this.attemptsLeft});

  final AlongPinVerdict verdict;

  /// Tries left after a wrong PIN; null when the server did not say.
  final int? attemptsLeft;
}

/// D-16b The driver types the rider's 4-digit pickup PIN to start the trip.
/// Four squircle boxes over a 3 x 4 keypad. The fourth digit submits; a
/// wrong PIN shakes the boxes on [AlongMoves.shake] with an error haptic.
class AlongPinEntryScreen extends StatefulWidget {
  const AlongPinEntryScreen({
    super.key,
    required this.riderName,
    required this.onSubmit,
    this.onVerified,
    this.onClose,
    this.onGetHelp,
    this.initialDigits = '',
    this.initialResult,
  });

  final String riderName;
  final Future<AlongPinResult> Function(String pin) onSubmit;
  final VoidCallback? onVerified;
  final VoidCallback? onClose;

  /// Shown once the PIN locks. Null (no support route) hides the action.
  final VoidCallback? onGetHelp;

  /// Gallery and test seeds.
  final String initialDigits;
  final AlongPinResult? initialResult;

  @override
  State<AlongPinEntryScreen> createState() => _AlongPinEntryScreenState();
}

class _AlongPinEntryScreenState extends State<AlongPinEntryScreen>
    with SingleTickerProviderStateMixin {
  static const _length = 4;

  late String _digits = widget.initialDigits;
  late AlongPinResult? _result = widget.initialResult;
  bool _checking = false;
  late final _shake = AnimationController(
    vsync: this,
    duration: AlongMoves.shake.duration,
  );

  bool get _locked => _result?.verdict == AlongPinVerdict.locked;
  bool get _enabled => !_checking && !_locked;

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _press(String digit) {
    if (!_enabled || _digits.length >= _length) return;
    AlongHaptics.tick(context);
    setState(() {
      _digits += digit;
      if (_result?.verdict != AlongPinVerdict.locked) _result = null;
    });
    if (_digits.length == _length) _submit();
  }

  void _back() {
    if (!_enabled || _digits.isEmpty) return;
    AlongHaptics.tick(context);
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _checking = true);
    AlongPinResult result;
    try {
      result = await widget.onSubmit(_digits);
    } catch (_) {
      result = const AlongPinResult(AlongPinVerdict.failed);
    }
    if (!mounted) return;
    if (result.verdict == AlongPinVerdict.verified) {
      AlongHaptics.success(context);
      setState(() {
        _checking = false;
        _result = result;
      });
      widget.onVerified?.call();
      return;
    }
    AlongHaptics.error(context);
    if (AlongMotionPolicy.play(context)) _shake.forward(from: 0);
    setState(() {
      _checking = false;
      _result = result;
      _digits = '';
    });
  }

  (String, Color)? _status(AlongPalette p) {
    final r = _result;
    if (_checking) return ('Checking…', p.ink.withValues(alpha: 0.72));
    if (r == null) return null;
    final name = widget.riderName;
    return switch (r.verdict) {
      AlongPinVerdict.verified => ('PIN confirmed', p.success),
      AlongPinVerdict.wrong => (
        r.attemptsLeft == null
            ? 'Wrong PIN. Try again.'
            : r.attemptsLeft == 1
            ? 'Wrong PIN. 1 try left.'
            : 'Wrong PIN. ${r.attemptsLeft} tries left.',
        p.danger,
      ),
      AlongPinVerdict.rateLimited => (
        'Too fast. Wait a moment, then try again.',
        p.danger,
      ),
      AlongPinVerdict.locked => (
        'Too many tries. Ask $name to confirm boarding in their app.',
        p.danger,
      ),
      AlongPinVerdict.failed => (
        'Couldn\'t check the PIN. Check your connection and try again.',
        p.danger,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final status = _status(p);
    return Scaffold(
      key: const Key('pin_entry'),
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _CloseButton(
                  onTap: widget.onClose ?? () => Navigator.maybePop(context),
                ),
              ),
              const SizedBox(height: 8),
              Text('Enter pickup PIN', style: AlongType.display(p)),
              const SizedBox(height: 4),
              Text(
                'Ask ${widget.riderName} for the 4-digit code in their app.',
                style: AlongType.body(p)
                    .copyWith(color: p.ink.withValues(alpha: 0.72)),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final t = _shake.value;
                  final dx = math.sin(t * math.pi * 6) * 12 * (1 - t);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: _Boxes(
                  filled: _digits.length,
                  locked: _locked,
                  error: status != null && status.$2 == p.danger,
                  done: _result?.verdict == AlongPinVerdict.verified,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: status == null
                    ? null
                    : Text(
                        status.$1,
                        key: const Key('pin_status'),
                        textAlign: TextAlign.center,
                        style: AlongType.label(p).copyWith(
                          color: status.$2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              if (_locked && widget.onGetHelp != null) ...[
                const SizedBox(height: 8),
                AlongButton(
                  key: const Key('pin_get_help'),
                  label: 'Get help',
                  variant: AlongButtonVariant.secondary,
                  onPressed: widget.onGetHelp,
                ),
              ],
              const Spacer(),
              _Keypad(enabled: _enabled, onDigit: _press, onBack: _back),
            ],
          ),
        ),
      ),
    );
  }
}

/// 48 x 48 squircle close. Outline-only glyph: the duotone X fill reads
/// as a smudge at this size.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: 'Close',
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        shape: AlongCraft.border(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('pin_close'),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: AlongIcon(
                AlongIcons.close,
                size: 24,
                color: p.ink,
                tone: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Boxes extends StatelessWidget {
  const _Boxes({
    required this.filled,
    required this.locked,
    required this.error,
    required this.done,
  });

  final int filled;
  final bool locked;
  final bool error;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final edge = done
        ? p.success
        : error
        ? p.danger
        : p.ink.withValues(alpha: 0.12);
    return Semantics(
      label: locked ? 'PIN locked' : 'PIN, $filled of 4 digits entered',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            AnimatedContainer(
              key: Key('pin_box_$i'),
              duration: AlongMoves.select.of(context),
              curve: AlongMoves.select.curve,
              width: 56,
              height: 64,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: p.surface,
                shape: AlongCraft.border(
                  16,
                  side: BorderSide(
                    color: i == filled && !locked && !error && !done
                        ? p.ink
                        : edge,
                    width: i == filled && !locked && !error ? 2 : 1,
                  ),
                ),
              ),
              child: locked && i == 0 && filled == 0
                  ? AlongIcon(AlongIcons.lock, size: 24, color: p.danger)
                  : AnimatedScale(
                      scale: i < filled ? 1 : 0,
                      duration: AlongMoves.pop.of(context),
                      curve: AlongMoves.pop.curve,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: ShapeDecoration(
                          color: done ? p.success : p.ink,
                          shape: AlongCraft.border(6),
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.enabled,
    required this.onDigit,
    required this.onBack,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> keys) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: keys[i]),
          ],
        ],
      ),
    );
    Widget digit(String d) => _Key(
      key: Key('pin_key_$d'),
      enabled: enabled,
      label: d,
      onTap: () => onDigit(d),
    );
    return Column(
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([
          const SizedBox(),
          digit('0'),
          _Key(
            key: const Key('pin_key_back'),
            enabled: enabled,
            icon: AlongIcons.backspace,
            semantics: 'Delete',
            quiet: true,
            onTap: onBack,
          ),
        ]),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.enabled,
    required this.onTap,
    this.label,
    this.icon,
    this.semantics,
    this.quiet = false,
  });

  final bool enabled;
  final VoidCallback onTap;
  final String? label;
  final IconData? icon;
  final String? semantics;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final ink = enabled ? p.ink : p.ink.withValues(alpha: 0.38);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semantics ?? label,
      excludeSemantics: true,
      child: Material(
        color: quiet ? Colors.transparent : p.surface,
        shape: AlongCraft.border(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: 60,
            child: Center(
              child: icon != null
                  ? AlongIcon(icon!, size: 24, color: ink)
                  : Text(
                      label!,
                      textScaler: TextScaler.noScaling,
                      style: AlongType.title(p).copyWith(
                        color: ink,
                        fontSize: 24,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
