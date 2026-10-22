/// A spoken or typed booking phrase. Place names come from the rider.
class VoiceBookingPhrase {
  const VoiceBookingPhrase({this.origin, required this.destination});

  final String? origin;
  final String destination;
}

const _pair =
    r'^(?:(?:from|daga|lati|site)\s+)?(.+?)\s+(?:to|go|reach|zuwa|si|gaa)\s+(.+)$';

/// Reads "Wuse to Berger", Pidgin "from Nyanya go CBD", Hausa and Yoruba
/// connectors. The words between the connectors are the rider's places.
VoiceBookingPhrase? parseBookingPhrase(String raw) {
  var text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  text = text.replaceAll(RegExp(r'[.!?]+$'), '');
  if (text.isEmpty) return null;
  if (text.toLowerCase().startsWith('abeg ')) {
    text = text.substring(5).trim();
  }
  if (text.isEmpty) return null;

  final match = RegExp(_pair, caseSensitive: false).firstMatch(text);
  if (match != null) {
    final origin = match.group(1)!.trim();
    final destination = match.group(2)!.trim();
    if (origin.isEmpty || destination.isEmpty) return null;
    if (_connector(origin) || _connector(destination)) return null;
    return VoiceBookingPhrase(origin: origin, destination: destination);
  }
  if (_connector(text)) return null;
  return VoiceBookingPhrase(destination: text);
}

bool _connector(String value) {
  const words = {
    'from',
    'to',
    'go',
    'reach',
    'daga',
    'zuwa',
    'lati',
    'si',
    'site',
    'gaa',
    'abeg',
  };
  return words.contains(value.toLowerCase());
}
