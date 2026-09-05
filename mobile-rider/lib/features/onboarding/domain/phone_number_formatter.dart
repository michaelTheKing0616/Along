/// Nigerian phone helpers for R-02 / R-03.
class PhoneNumberFormatter {
  static const countryCode = '+234';

  /// Validates a local Nigerian mobile number (10 digits, leading 7/8/9).
  static bool isValidLocal(String digits) {
    if (digits.length != 10) return false;
    final first = digits[0];
    return first == '7' || first == '8' || first == '9';
  }

  /// Converts local digits to E.164 (+234XXXXXXXXXX).
  static String toE164(String localDigits) {
    final digits = localDigits.replaceAll(RegExp(r'\D'), '');
    final normalized = digits.startsWith('0') ? digits.substring(1) : digits;
    return '$countryCode$normalized';
  }

  /// Formats E.164 for display (+234 801 234 5678).
  static String formatDisplay(String e164) {
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || !digits.startsWith('234')) {
      return e164;
    }
    final local = digits.substring(3);
    return '$countryCode ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
  }
}
