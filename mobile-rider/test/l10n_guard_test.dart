import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fails CI on missing/extra keys, mismatched placeholders, or
/// unfinished-feature copy ("Phase", "stub", "coming soon") in any locale.
void main() {
  const locales = ['ha', 'ig', 'yo', 'pcm'];
  final banned = RegExp(
    r'\bphase\b|\bstub\b|coming soon',
    caseSensitive: false,
  );
  final placeholder = RegExp(r'\{(\w+)[,}]');

  Map<String, String> messages(String locale) {
    final raw = jsonDecode(
      File('lib/l10n/app_$locale.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    return {
      for (final e in raw.entries)
        if (!e.key.startsWith('@')) e.key: e.value as String,
    };
  }

  Set<String> names(String s) =>
      placeholder.allMatches(s).map((m) => m.group(1)!).toSet();

  final en = messages('en');

  for (final locale in locales) {
    test('$locale has every key with matching placeholders', () {
      final tr = messages(locale);
      expect(
        en.keys.where((k) => !tr.containsKey(k)).toList(),
        isEmpty,
        reason: 'missing in $locale',
      );
      expect(
        tr.keys.where((k) => !en.containsKey(k)).toList(),
        isEmpty,
        reason: 'stale keys in $locale',
      );
      final bad = [
        for (final k in en.keys)
          if (tr.containsKey(k) && !_sameSet(names(en[k]!), names(tr[k]!))) k,
      ];
      expect(bad, isEmpty, reason: 'placeholder mismatch in $locale');
    });
  }

  test('no unfinished-feature copy in any locale', () {
    final hits = [
      for (final locale in ['en', ...locales])
        for (final e in messages(locale).entries)
          if (banned.hasMatch(e.value)) '$locale.${e.key}: ${e.value}',
    ];
    expect(hits, isEmpty);
  });

  test('no unfinished-feature string literals in lib/', () {
    final literal = RegExp(
      r'''(['"])[^'"\n]*(Phase \d|coming soon|\(stub\))[^'"\n]*\1''',
      caseSensitive: false,
    );
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File ||
          !f.path.endsWith('.dart') ||
          f.path.contains('/l10n/')) {
        continue;
      }
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (literal.hasMatch(line)) hits.add('${f.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty);
  });
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
