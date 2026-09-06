/// Parses Along QR payloads — accepts only `along.ng/p/*` and `along://p/<code>`.
abstract final class QrPayloadParser {
  static const _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Returns normalised 8-char driver code, or null if not an Along payload.
  static String? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return _normaliseCode(trimmed);
    }

    if (uri.scheme == 'along' && uri.host == 'p') {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) return null;
      return _normaliseCode(segments.first);
    }

    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == 'along.ng' &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'p') {
      return _normaliseCode(uri.pathSegments[1]);
    }

    return null;
  }

  /// Extracts the dynamic payment token from a QR URL, if present.
  static String? tokenFromUrl(String url) {
    try {
      return Uri.parse(url).queryParameters['t'];
    } catch (_) {
      return null;
    }
  }

  static String? _normaliseCode(String input) {
    final upper = input.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');
    final mapped = upper
        .split('')
        .map((c) {
          if (_crockford.contains(c)) return c;
          if (c == 'I') return '1';
          if (c == 'L') return '1';
          if (c == 'O') return '0';
          if (c == 'U') return 'V';
          return '';
        })
        .join();
    if (mapped.length != 8) return null;
    return mapped;
  }

  static bool isAlongPayload(String raw) => parse(raw) != null;
}

/// Builds static or dynamic Along QR payload URLs (doc 14 §2).
abstract final class QrUrlBuilder {
  static String staticDriverUrl({
    required String driverCode,
    String? publicOrigin,
  }) {
    final origin = publicOrigin?.trim();
    if (origin != null && origin.isNotEmpty) {
      final base = origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
      return '$base/p/$driverCode';
    }
    return 'along://p/$driverCode';
  }

  static String dynamicPaymentUrl({
    required String driverCode,
    required String token,
    String? publicOrigin,
  }) {
    final base = staticDriverUrl(
      driverCode: driverCode,
      publicOrigin: publicOrigin,
    );
    final separator = base.contains('?') ? '&' : '?';
    return '$base${separator}t=$token';
  }
}
