/// Transport mode codes aligned with `mode_config.code`.
enum TransportMode {
  car('car'),
  keke('keke'),
  okada('okada'),
  minibus('minibus');

  const TransportMode(this.code);

  final String code;

  static TransportMode? tryParse(String? code) {
    if (code == null) return null;
    for (final mode in TransportMode.values) {
      if (mode.code == code) return mode;
    }
    return null;
  }
}
