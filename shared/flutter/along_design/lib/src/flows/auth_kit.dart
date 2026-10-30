import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../craft.dart';
import '../icons.dart';
import '../palette.dart';
import '../theme.dart';
import '../tokens.g.dart';
import '../type.dart';
import 'delights.dart';

/// Sign-in building blocks shared by the rider and driver apps.
/// One screen per decision, no spinners, inline states only.

/// One line of the first-run value story.
class AlongStorySlide {
  const AlongStorySlide({required this.headline, required this.body});

  final String headline;
  final String body;
}

/// Photo band at the top of the phone step. Swipe through three short
/// reasons to use Along. It never blocks the number field below.
class AlongValueStory extends StatefulWidget {
  const AlongValueStory({super.key, required this.slides, this.height});

  final List<AlongStorySlide> slides;
  final double? height;

  @override
  State<AlongValueStory> createState() => _AlongValueStoryState();
}

class _AlongValueStoryState extends State<AlongValueStory> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const ink = Color(0xFFFFFFFF);
    // The photo keeps the light paper type so it reads in dark mode too.
    final paper = AlongPalette.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final roomy = scaler.scale(1) > 1.05;
    // The story is a poster: cap its type so it never runs into the mark,
    // and give large text a taller band instead.
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: scaler.clamp(maxScaleFactor: 1.15)),
      child: Theme(
        data: alongTheme(),
        child: SizedBox(
          height: widget.height == null
              ? null
              : widget.height! * (roomy ? 1.12 : 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AlongGrade(
                child: Image.asset(
                  'assets/photos/onboarding-fleet.jpg',
                  package: 'along_design',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
              ),
              const AlongNoise(opacity: 0.03),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x80101828),
                      Color(0x00101828),
                      Color(0x33101828),
                      Color(0xCC101828),
                    ],
                    stops: [0, 0.3, 0.5, 1],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, top + 12, 20, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Transform.scale(
                    scale: 0.72,
                    alignment: Alignment.topLeft,
                    child: const AlongWordmark(color: ink),
                  ),
                ),
              ),
              Positioned.fill(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    for (final s in widget.slides)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 52),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.headline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AlongType.display(paper)
                                  .copyWith(color: ink, height: 1.1),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AlongType.body(paper)
                                  .copyWith(color: const Color(0xEBFFFFFF)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                bottom: 24,
                child: AlongStoryDots(
                  count: widget.slides.length,
                  index: _index,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yellow pill for the current story line, white dots for the rest.
class AlongStoryDots extends StatelessWidget {
  const AlongStoryDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${index + 1} / $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index
                    ? const Color(0xFFF7D117)
                    : const Color(0xB3FFFFFF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Page frame for each sign-in step: optional hero, title, body, notice,
/// and a pinned action at the thumb.
class AlongAuthScaffold extends StatelessWidget {
  const AlongAuthScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.bottom,
    this.subtitle,
    this.hero,
    this.onBack,
    this.backLabel = 'Back',
    this.notice,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget bottom;
  final Widget? hero;
  final VoidCallback? onBack;
  final String backLabel;
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final mq = MediaQuery.of(context);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AlongType.display(p)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: AlongType.bodyMuted(p)),
          ],
          const SizedBox(height: 20),
          body,
          const SizedBox(height: 24),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: p.bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hero != null)
                          hero!
                        else
                          SizedBox(height: mq.padding.top),
                        if (onBack != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Semantics(
                                button: true,
                                label: backLabel,
                                child: InkResponse(
                                  key: const Key('auth_back'),
                                  onTap: onBack,
                                  radius: 24,
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Icon(
                                      AlongIcons.back,
                                      size: 24,
                                      color: p.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        content,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              16 + (mq.viewInsets.bottom > 0 ? 0 : mq.padding.bottom),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kept by the button so it is never scrolled out of view.
                if (notice != null) ...[notice!, const SizedBox(height: 12)],
                bottom,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Groups a Nigerian number as 801 234 5678 while typing.
class AlongPhoneGroupFormatter extends TextInputFormatter {
  const AlongPhoneGroupFormatter();

  static String group(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) b.write(' ');
      b.write(digits[i]);
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);
    final text = group(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Number field with the dial code. Autofills from the SIM or keyboard.
class AlongPhoneInput extends StatelessWidget {
  const AlongPhoneInput({
    super.key,
    required this.dialCode,
    required this.controller,
    this.fieldKey,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = true,
    this.enabled = true,
    this.hint = '801 234 5678',
  });

  final String dialCode;
  final TextEditingController controller;
  final Key? fieldKey;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final hasError = errorText != null;
    final digits = AlongType.title(p)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AlongCraft.fill(
            p.surface,
            corner: AlongRadius.control.x,
            side: BorderSide(
              color: hasError ? p.danger : p.line,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(dialCode, style: digits),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: p.line,
              ),
              Expanded(
                child: TextField(
                  key: fieldKey,
                  controller: controller,
                  autofocus: autofocus,
                  enabled: enabled,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: const [AlongPhoneGroupFormatter()],
                  style: digits,
                  cursorColor: p.ink,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: digits.copyWith(color: p.muted),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) AlongFieldError(errorText!),
      ],
    );
  }
}

/// Red caption under a field, with a mark so it does not rely on colour.
class AlongFieldError extends StatelessWidget {
  const AlongFieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(AlongIcons.info, size: 16, color: p.danger),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: AlongType.caption(p).copyWith(color: p.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Six boxes over one hidden field. The system fills the code from the
/// text message and [onCompleted] fires on the last digit, no button.
class AlongCodeInput extends StatelessWidget {
  const AlongCodeInput({
    super.key,
    required this.controller,
    this.fieldKey,
    this.length = 6,
    this.errorText,
    this.checking = false,
    this.checkingLabel = 'Checking',
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final Key? fieldKey;
  final int length;
  final String? errorText;
  final bool checking;
  final String checkingLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final code = controller.text;
                return Row(
                  children: [
                    for (var i = 0; i < length; i++) ...[
                      if (i > 0) SizedBox(width: i == length ~/ 2 ? 16 : 8),
                      Expanded(
                        child: _CodeBox(
                          digit: i < code.length ? code[i] : null,
                          active: !checking && i == code.length,
                          error: hasError,
                          checking: checking,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  key: fieldKey,
                  controller: controller,
                  autofocus: autofocus,
                  readOnly: checking,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  keyboardType: TextInputType.number,
                  maxLength: length,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    onChanged?.call(v);
                    if (v.length == length) onCompleted?.call(v);
                  },
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          AlongFieldError(errorText!)
        else if (checking)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                checkingLabel,
                style: AlongType.caption(p).copyWith(color: p.muted),
              ),
            ),
          ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.digit,
    required this.active,
    required this.error,
    required this.checking,
  });

  final String? digit;
  final bool active;
  final bool error;
  final bool checking;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final edge = error
        ? p.danger
        : active
        ? p.ink
        : p.line;
    return AspectRatio(
      aspectRatio: 0.82,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: checking ? 0.55 : 1,
        child: Container(
          alignment: Alignment.center,
          decoration: AlongCraft.fill(
            p.surface,
            corner: AlongRadius.control.x,
            side: BorderSide(color: edge, width: active || error ? 2 : 1),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              digit ?? '',
              style: AlongType.display(p)
                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ),
      ),
    );
  }
}

enum AlongAuthNoticeTone { error, offline, wait }

/// Inline message inside the step, never a snackbar.
class AlongAuthNotice extends StatelessWidget {
  const AlongAuthNotice({
    super.key,
    required this.tone,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final AlongAuthNoticeTone tone;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final (Color edge, IconData icon) = switch (tone) {
      AlongAuthNoticeTone.error => (p.danger, AlongIcons.info),
      AlongAuthNoticeTone.offline => (p.ink, AlongIcons.online),
      AlongAuthNoticeTone.wait => (p.ink, AlongIcons.schedule),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: AlongCraft.fill(
          Color.alphaBlend(edge.withValues(alpha: 0.08), p.surface),
          corner: AlongRadius.control.x,
          side: BorderSide(color: edge.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: edge),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: AlongType.body(p))),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 40),
                  foregroundColor: p.ink,
                ),
                child: Text(actionLabel!, style: AlongType.label(p)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Resend link with a live countdown and a way back to the number.
class AlongResendRow extends StatelessWidget {
  const AlongResendRow({
    super.key,
    required this.secondsRemaining,
    required this.countdownLabel,
    required this.resendLabel,
    required this.changeLabel,
    required this.onResend,
    required this.onChange,
    this.resendKey,
    this.changeKey,
    this.enabled = true,
  });

  /// False while a rate limit or the network blocks a resend.
  final bool enabled;
  final int secondsRemaining;
  final String Function(String clock) countdownLabel;
  final String resendLabel;
  final String changeLabel;
  final VoidCallback onResend;
  final VoidCallback onChange;
  final Key? resendKey;
  final Key? changeKey;

  static String clock(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final waiting = secondsRemaining > 0;
    Widget link(String label, VoidCallback? onTap, Key? key, Color color) {
      return TextButton(
        key: key,
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: color,
          disabledForegroundColor: p.muted,
        ),
        child: Text(
          label,
          style: AlongType.label(p).copyWith(
            color: onTap == null ? p.muted : color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        link(
          waiting ? countdownLabel(clock(secondsRemaining)) : resendLabel,
          waiting || !enabled ? null : onResend,
          resendKey,
          p.ink,
        ),
        link(changeLabel, onChange, changeKey, p.ink),
      ],
    );
  }
}

/// One permission explained before the system asks.
class AlongPrimeItem {
  const AlongPrimeItem({
    required this.icon,
    required this.title,
    required this.body,
    this.granted = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool granted;
}

/// List of what Along will ask for and why, so one tap covers them all.
class AlongPermissionPrime extends StatelessWidget {
  const AlongPermissionPrime({super.key, required this.items});

  final List<AlongPrimeItem> items;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(p, radius: AlongRadius.card.x),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 68,
                color: p.line.withValues(alpha: 0.6),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: AlongCraft.fill(
                      items[i].granted ? p.success : p.recessed,
                      corner: 12,
                    ),
                    child: Icon(
                      items[i].granted ? AlongIcons.check : items[i].icon,
                      size: 20,
                      color: items[i].granted ? const Color(0xFFFFFFFF) : p.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].title, style: AlongType.title(p)),
                        const SizedBox(height: 2),
                        Text(items[i].body, style: AlongType.bodyMuted(p)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
