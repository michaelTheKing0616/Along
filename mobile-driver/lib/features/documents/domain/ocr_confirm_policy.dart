/// OCR confirm policy — IDs must never auto-fill without explicit confirm (D-06).
class OcrConfirmPolicy {
  const OcrConfirmPolicy._();

  static final _sensitiveKeyPattern = RegExp(
    r'id|nin|license|licence|number',
    caseSensitive: false,
  );

  /// Whether a field key represents a sensitive identifier.
  static bool isSensitiveField(String key) => _sensitiveKeyPattern.hasMatch(key);

  /// Whether OCR may auto-apply this field without user action (always false for IDs).
  static bool mayAutoApply(String key) => !isSensitiveField(key);

  /// Applies a confirmed suggestion to the editable field map.
  static Map<String, String> applyConfirmed({
    required Map<String, String> current,
    required String key,
    required String value,
  }) {
    return {...current, key: value};
  }

  /// Strips sensitive keys from hints sent to the server as client_ocr_hint.
  static Map<String, String> redactForSubmit(Map<String, String> confirmed) {
    return Map.fromEntries(
      confirmed.entries.where((entry) => !isSensitiveField(entry.key)),
    );
  }
}
