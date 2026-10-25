import 'package:flutter/widgets.dart';

/// One icon family. Phosphor Duotone (MIT), drawn from the package font at
/// 20 or 24. [Icon] paints the stroke. [AlongIcon] paints the tone as well.
/// The phosphor_flutter library extends [IconData], which this SDK marks
/// final, so the code points live here and the font stays in the package.
abstract final class AlongIcons {
  static const _family = 'PhosphorDuotone';
  static const _package = 'phosphor_flutter';

  static const menu = IconData(
    0xe2f1,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const search = IconData(
    0xe30d,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const locate = IconData(
    0xe1d7,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const seat = IconData(
    0xeb8f,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const sos = IconData(
    0xe9b9,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const shield = IconData(
    0xe40d,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const plate = IconData(
    0xe113,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const wallet = IconData(
    0xe68b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const earnings = IconData(
    0xe78f,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const online = IconData(
    0xeb09,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const share = IconData(
    0xe40b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const back = IconData(
    0xe059,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const home = IconData(
    0xe2c3,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const work = IconData(
    0xe0ef,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const call = IconData(
    0xe3b9,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const chat = IconData(
    0xe169,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const star = IconData(
    0xe46b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const schedule = IconData(
    0xe19b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const receipt = IconData(
    0xe3f1,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const verified = IconData(
    0xe607,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const check = IconData(
    0xe183,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const info = IconData(
    0xe2cf,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const close = IconData(
    0xe4f7,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const navigate = IconData(
    0xeadf,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const keke = IconData(
    0xe825,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const okada = IconData(
    0xe80b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const taxi = IconData(
    0xe903,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const danfo = IconData(
    0xe827,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const bus = IconData(
    0xe107,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const caretUp = IconData(
    0xe13d,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const caretDown = IconData(
    0xe137,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const caretRight = IconData(
    0xe13b,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const user = IconData(
    0xe4c3,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const plus = IconData(
    0xe3d5,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const path = IconData(
    0xe39d,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const arrowRight = IconData(
    0xe06d,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const female = IconData(
    0xe6e1,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const luggage = IconData(
    0xe5af,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const tag = IconData(
    0xe479,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const dots = IconData(
    0xe1ff,
    fontFamily: _family,
    fontPackage: _package,
  );

  static const backspace = IconData(
    0xe0af,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const lock = IconData(
    0xe309,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const password = IconData(
    0xe753,
    fontFamily: _family,
    fontPackage: _package,
  );

  static const send = IconData(
    0xe397,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const checks = IconData(
    0xe53b,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Fill layer that sits under the stroke in the duotone font.
  static const tone = <int, int>{
    0xe397: 0xe396,
    0xe53b: 0xe53a,
    0xe0af: 0xe0ae,
    0xe309: 0xe308,
    0xe753: 0xe752,
    0xe2f1: 0xe2f0,
    0xe30d: 0xe30c,
    0xe1d7: 0xe1d6,
    0xeb8f: 0xeb8e,
    0xe9b9: 0xe9b8,
    0xe40d: 0xe40a,
    0xe113: 0xe112,
    0xe68b: 0xe68a,
    0xe78f: 0xe78e,
    0xeb09: 0xeb08,
    0xe40b: 0xe408,
    0xe059: 0xe058,
    0xe2c3: 0xe2c2,
    0xe0ef: 0xe0ee,
    0xe3b9: 0xe3b8,
    0xe169: 0xe168,
    0xe46b: 0xe46a,
    0xe19b: 0xe19a,
    0xe3f1: 0xe3ec,
    0xe607: 0xe606,
    0xe183: 0xe182,
    0xe2cf: 0xe2ce,
    0xe4f7: 0xe4f6,
    0xeadf: 0xeade,
    0xe825: 0xe824,
    0xe80b: 0xe80a,
    0xe903: 0xe902,
    0xe827: 0xe826,
    0xe107: 0xe106,
    0xe13d: 0xe13c,
    0xe137: 0xe136,
    0xe13b: 0xe13a,
    0xe4c3: 0xe4c2,
    0xe3d5: 0xe3d4,
    0xe39d: 0xe39c,
    0xe06d: 0xe06c,
    0xe6e1: 0xe6e0,
    0xe5af: 0xe5ae,
    0xe479: 0xe478,
    0xe1ff: 0xe1fe,
  };
}

/// Duotone Phosphor glyph. Small sizes snap to 20 or 24; hero sizes (28+)
/// render as given. Glyphs never follow the text scaler.
class AlongIcon extends StatelessWidget {
  const AlongIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.toneColor,
    this.tone = true,
  });

  final IconData icon;
  final double size;
  final Color? color;

  /// Fill colour for the duotone layer. Defaults to [color] at 32%.
  final Color? toneColor;

  /// False draws the outline alone, for an unselected state.
  final bool tone;

  @override
  Widget build(BuildContext context) {
    final snapped = size <= 20
        ? 20.0
        : size <= 24
        ? 24.0
        : size;
    final paint =
        color ?? IconTheme.of(context).color ?? const Color(0xFF111111);
    final glyph = tone ? AlongIcons.tone[icon.codePoint] : null;
    final style = TextStyle(
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      fontSize: snapped,
      height: 1,
      color: paint,
    );
    return SizedBox(
      width: snapped,
      height: snapped,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glyph != null)
            Text(
              String.fromCharCode(glyph),
              textScaler: TextScaler.noScaling,
              style: style.copyWith(
                color: toneColor ?? paint.withValues(alpha: 0.32),
              ),
            ),
          Text(
            String.fromCharCode(icon.codePoint),
            textScaler: TextScaler.noScaling,
            style: style,
          ),
        ],
      ),
    );
  }
}
