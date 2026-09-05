/// Formats a fare amount in Nigerian Naira (major units) for display.
///
/// Uses the bundled Inter subset so ₦ (U+20A6) renders correctly (TS-DS-02).
String formatMoney(int amountNaira) {
  final formatted = amountNaira.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '₦$formatted';
}
