import 'package:flutter/services.dart';

/// Registers Geist and Inter under the bare family names AlongType asks
/// for. Fonts a package declares are only registered as
/// `packages/along_design/<family>`, so an app that depends on this
/// package would otherwise fall back to the system face. Call once before
/// runApp (and in app golden tests). Safe to call more than once.
abstract final class AlongFonts {
  static Future<void>? _loading;

  static Future<void> ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    const faces = {
      'Geist': 'packages/along_design/assets/fonts/Geist-Variable.ttf',
      'Inter': 'packages/along_design/assets/fonts/Inter.ttf',
    };
    for (final MapEntry(key: family, value: asset) in faces.entries) {
      try {
        await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
      } on Object {
        // Inside along_design itself the asset key has no packages/ prefix
        // and the family is already registered. Nothing to do.
      }
    }
  }
}
