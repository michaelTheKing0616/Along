/// Phone helpers driven by [countries.phone_prefix] (R-02 / R-03).
class PhoneNumberFormatter {
  const PhoneNumberFormatter({
    required this.phonePrefix,
    this.dialCodeDigits,
    this.localLength = 10,
    this.validFirstDigits = const {'7', '8', '9'},
  });

  final String phonePrefix;
  final String? dialCodeDigits;
  final int localLength;
  final Set<String> validFirstDigits;

  String get _dialDigits =>
      dialCodeDigits ?? phonePrefix.replaceAll(RegExp(r'\D'), '');

  /// Local subscriber digits: strips spaces and a leading trunk `0`
  /// (`0803…` → `803…`) so the field matches how people actually type NG numbers.
  String localSubscriberDigits(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Validates a local mobile number for the configured country.
  bool isValidLocal(String digits) {
    final normalized = localSubscriberDigits(digits);
    if (normalized.length != localLength) return false;
    if (validFirstDigits.isEmpty) return true;
    return validFirstDigits.contains(normalized[0]);
  }

  /// Converts local digits to E.164.
  String toE164(String localDigits) {
    return '$phonePrefix${localSubscriberDigits(localDigits)}';
  }

  /// Formats E.164 for display.
  String formatDisplay(String e164) {
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    if (digits.length < _dialDigits.length + 7 ||
        !digits.startsWith(_dialDigits)) {
      return e164;
    }
    final local = digits.substring(_dialDigits.length);
    if (local.length == 10) {
      return '$phonePrefix ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
    }
    return '$phonePrefix $local';
  }
}
