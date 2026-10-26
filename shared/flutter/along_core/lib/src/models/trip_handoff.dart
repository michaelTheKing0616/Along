/// Rider-only pickup handoff details from the trip view: the PIN the rider
/// says at the door (while the driver is arriving), and whether the driver can
/// be reached through the trip-contact relay. The phone number itself is never
/// in the trip payload.
class TripPickupHandoff {
  const TripPickupHandoff({this.pin, this.contactAvailable = false});

  final String? pin;
  final bool contactAvailable;

  static TripPickupHandoff? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final pin = raw['pin'];
    final handoff = TripPickupHandoff(
      pin: pin is String && RegExp(r'^\d{4}$').hasMatch(pin) ? pin : null,
      contactAvailable: raw['contact_available'] == true,
    );
    return handoff.pin == null && !handoff.contactAvailable ? null : handoff;
  }
}
