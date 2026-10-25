/// Rider-only pickup handoff details from the trip view: the PIN the rider
/// says at the door (while the driver is arriving) and the driver's phone.
class TripHandoff {
  const TripHandoff({this.pin, this.driverPhone});

  final String? pin;
  final String? driverPhone;

  static TripHandoff? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final pin = raw['pin'];
    final phone = raw['driver_phone'];
    final handoff = TripHandoff(
      pin: pin is String && RegExp(r'^\d{4}$').hasMatch(pin) ? pin : null,
      driverPhone: phone is String && phone.trim().isNotEmpty
          ? phone.trim()
          : null,
    );
    return handoff.pin == null && handoff.driverPhone == null ? null : handoff;
  }
}
