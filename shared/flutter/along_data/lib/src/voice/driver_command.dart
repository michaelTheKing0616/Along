/// A driver voice command. Seat names and statuses are the words they said.
class DriverVoiceCommand {
  const DriverVoiceCommand(this.intent, {this.seatRef, this.seatStatus});

  final DriverVoiceIntent intent;
  final String? seatRef;
  final String? seatStatus;
}

enum DriverVoiceIntent { accept, decline, online, offline, full, empty, seat }

const _commands = <String, DriverVoiceIntent>{
  'accept': DriverVoiceIntent.accept,
  'yes': DriverVoiceIntent.accept,
  'gree': DriverVoiceIntent.accept,
  'i gree': DriverVoiceIntent.accept,
  'i don accept': DriverVoiceIntent.accept,
  'decline': DriverVoiceIntent.decline,
  'no': DriverVoiceIntent.decline,
  'reject': DriverVoiceIntent.decline,
  'cancel am': DriverVoiceIntent.decline,
  'online': DriverVoiceIntent.online,
  'i dey': DriverVoiceIntent.online,
  'go online': DriverVoiceIntent.online,
  'offline': DriverVoiceIntent.offline,
  'i don stop': DriverVoiceIntent.offline,
  'go offline': DriverVoiceIntent.offline,
  'full': DriverVoiceIntent.full,
  'e full': DriverVoiceIntent.full,
  'empty': DriverVoiceIntent.empty,
  'e empty': DriverVoiceIntent.empty,
};

/// Parses English and Pidgin driver commands. Unknown phrases return null.
DriverVoiceCommand? parseDriverVoice(String raw) {
  final text = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (text.isEmpty) return null;
  final direct = _commands[text];
  if (direct != null) return DriverVoiceCommand(direct);
  if (!text.startsWith('seat ')) return null;
  final rest = text.substring(5).trim();
  final match = RegExp(r'^(.+?)\s+(free|open|occupied|held|hold|full)$')
      .firstMatch(rest);
  if (match == null) return null;
  final status = switch (match.group(2)) {
    'open' || 'free' => 'free',
    'hold' || 'held' => 'held',
    _ => 'occupied',
  };
  return DriverVoiceCommand(
    DriverVoiceIntent.seat,
    seatRef: match.group(1)!.trim(),
    seatStatus: status,
  );
}
