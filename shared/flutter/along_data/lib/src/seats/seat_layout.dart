/// Driver-built seat layout (JSON v1). Presets are starting points only.
class SeatLayout {
  const SeatLayout({this.version = 1, required this.body, required this.rows});

  final int version;

  /// Visual chrome token stored in the layout: cabin, bench, bike, or coach.
  final String body;
  final List<SeatRow> rows;

  static const bodies = {'cabin', 'bench', 'bike', 'coach'};
  static const maxTotalSeats = 80;
  static const maxRows = 24;
  static const maxSeatsPerRow = 6;

  int get passengerCount => rows.fold<int>(
    0,
    (sum, row) => sum + row.seats.where((seat) => seat.isPassenger).length,
  );

  int get totalSeats => rows.fold<int>(0, (sum, row) => sum + row.seats.length);

  bool overCapacity(int reviewSeatMax) => passengerCount > reviewSeatMax;

  String? rowIdOf(String seatId) {
    for (final row in rows) {
      if (row.seats.any((seat) => seat.id == seatId)) return row.id;
    }
    return null;
  }

  SeatSpec? seatById(String seatId) {
    for (final row in rows) {
      for (final seat in row.seats) {
        if (seat.id == seatId) return seat;
      }
    }
    return null;
  }

  /// Generic fallback used only when a mode has no preset JSON.
  factory SeatLayout.starter({required int passengerSeats}) {
    final passengers = passengerSeats < 1 ? 1 : passengerSeats;
    final rows = <SeatRow>[
      SeatRow(
        id: 'cab',
        seats: const [SeatSpec(id: 'drv', role: 'driver', label: 'Driver')],
      ),
    ];
    var placed = 0;
    var rowNumber = 1;
    while (placed < passengers && rows.length < maxRows) {
      final seats = <SeatSpec>[];
      final room = passengers - placed;
      final count = room > 3 ? 3 : room;
      for (var i = 0; i < count; i++) {
        placed += 1;
        seats.add(
          SeatSpec(
            id: 'r${rowNumber}s$placed',
            role: 'passenger',
            label: 'Seat $placed',
          ),
        );
      }
      rows.add(SeatRow(id: 'r$rowNumber', seats: seats));
      rowNumber += 1;
    }
    return SeatLayout(body: 'cabin', rows: rows);
  }

  factory SeatLayout.fromJson(Map<String, dynamic> json) {
    final version = (json['version'] as num?)?.toInt() ?? 0;
    final body = json['body'] as String? ?? '';
    final rawRows = json['rows'];
    if (version != 1 || !bodies.contains(body) || rawRows is! List) {
      throw const FormatException('VALIDATION');
    }
    final rows = <SeatRow>[];
    final seen = <String>{};
    var drivers = 0;
    var passengers = 0;
    for (final raw in rawRows) {
      if (raw is! Map) throw const FormatException('VALIDATION');
      final row = SeatRow.fromJson(Map<String, dynamic>.from(raw));
      if (row.id.isEmpty ||
          row.id.length > 40 ||
          !seen.add(row.id) ||
          row.seats.isEmpty ||
          row.seats.length > maxSeatsPerRow) {
        throw const FormatException('VALIDATION');
      }
      for (final seat in row.seats) {
        if (seat.id.isEmpty ||
            seat.id.length > 40 ||
            !seen.add(seat.id) ||
            seat.label.trim().isEmpty ||
            seat.label.length > 40 ||
            (seat.role != 'driver' && seat.role != 'passenger')) {
          throw const FormatException('VALIDATION');
        }
        if (seat.role == 'driver') {
          drivers += 1;
        } else {
          passengers += 1;
        }
      }
      rows.add(row);
    }
    if (rows.isEmpty ||
        rows.length > maxRows ||
        drivers != 1 ||
        passengers < 1 ||
        drivers + passengers > maxTotalSeats) {
      throw const FormatException('VALIDATION');
    }
    return SeatLayout(version: version, body: body, rows: rows);
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'body': body,
    'rows': rows.map((row) => row.toJson()).toList(),
  };

  SeatLayout addRow() {
    if (rows.length >= maxRows || totalSeats >= maxTotalSeats) return this;
    final id = _freshId('row');
    final seatId = _freshId('s');
    return SeatLayout(
      body: body,
      rows: [
        ...rows,
        SeatRow(
          id: id,
          seats: [SeatSpec(id: seatId, role: 'passenger', label: 'Seat')],
        ),
      ],
    );
  }

  SeatLayout removeRow(String rowId) {
    if (rows.length <= 1) return this;
    final row = rows.cast<SeatRow?>().firstWhere(
      (item) => item!.id == rowId,
      orElse: () => null,
    );
    if (row == null) return this;
    final remaining = rows.where((item) => item.id != rowId).toList();
    final passengersLeft = remaining.fold<int>(
      0,
      (sum, item) => sum + item.seats.where((seat) => seat.isPassenger).length,
    );
    if (passengersLeft < 1 && !row.seats.any((seat) => seat.isPassenger)) {
      return this;
    }
    var next = SeatLayout(body: body, rows: remaining);
    if (passengersLeft < 1) return this;
    if (!next.rows.any(
      (item) => item.seats.any((seat) => seat.role == 'driver'),
    )) {
      final fallback = next.rows
          .expand((item) => item.seats)
          .firstWhere((seat) => seat.isPassenger);
      next = next.markDriver(fallback.id);
    }
    return next.passengerCount >= 1 ? next : this;
  }

  SeatLayout addSeat(String rowId) {
    if (totalSeats >= maxTotalSeats) return this;
    return SeatLayout(
      body: body,
      rows: [
        for (final row in rows)
          if (row.id != rowId || row.seats.length >= maxSeatsPerRow)
            row
          else
            SeatRow(
              id: row.id,
              seats: [
                ...row.seats,
                SeatSpec(id: _freshId('s'), role: 'passenger', label: 'Seat'),
              ],
            ),
      ],
    );
  }

  SeatLayout removeSeat(String rowId, String seatId) {
    final row = rows.cast<SeatRow?>().firstWhere(
      (item) => item!.id == rowId,
      orElse: () => null,
    );
    if (row == null) return this;
    final seat = row.seats.cast<SeatSpec?>().firstWhere(
      (item) => item!.id == seatId,
      orElse: () => null,
    );
    if (seat == null) return this;
    if (row.seats.length == 1) return removeRow(rowId);
    if (seat.isPassenger && passengerCount <= 1) return this;
    final rowsNext = [
      for (final item in rows)
        if (item.id != rowId)
          item
        else
          SeatRow(
            id: item.id,
            seats: item.seats.where((s) => s.id != seatId).toList(),
          ),
    ];
    var next = SeatLayout(body: body, rows: rowsNext);
    if (seat.role == 'driver') {
      final fallback = next.rows
          .expand((item) => item.seats)
          .firstWhere((s) => s.isPassenger);
      next = next.markDriver(fallback.id);
    }
    return next.passengerCount >= 1 ? next : this;
  }

  SeatLayout markDriver(String seatId) {
    if (seatById(seatId) == null) return this;
    return SeatLayout(
      body: body,
      rows: [
        for (final row in rows)
          SeatRow(
            id: row.id,
            seats: [
              for (final seat in row.seats)
                SeatSpec(
                  id: seat.id,
                  label: seat.label,
                  role: seat.id == seatId ? 'driver' : 'passenger',
                ),
            ],
          ),
      ],
    );
  }

  String _freshId(String prefix) {
    final taken = <String>{
      for (final row in rows) row.id,
      for (final row in rows) ...row.seats.map((seat) => seat.id),
    };
    var n = 1;
    while (taken.contains('$prefix$n')) {
      n += 1;
    }
    return '$prefix$n';
  }
}

class SeatRow {
  const SeatRow({required this.id, required this.seats});

  final String id;
  final List<SeatSpec> seats;

  factory SeatRow.fromJson(Map<String, dynamic> json) {
    final raw = json['seats'];
    if (raw is! List) throw const FormatException('VALIDATION');
    return SeatRow(
      id: json['id'] as String? ?? '',
      seats: [
        for (final seat in raw)
          if (seat is Map)
            SeatSpec.fromJson(Map<String, dynamic>.from(seat))
          else
            throw const FormatException('VALIDATION'),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seats': seats.map((seat) => seat.toJson()).toList(),
  };
}

class SeatSpec {
  const SeatSpec({required this.id, required this.role, required this.label});

  final String id;
  final String role;
  final String label;

  bool get isPassenger => role == 'passenger';

  factory SeatSpec.fromJson(Map<String, dynamic> json) {
    return SeatSpec(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'role': role, 'label': label};
}

/// Canonical Abuja along-car starting layout: 2 front passengers + 4 back.
const Map<String, dynamic> alongCarPreset = {
  'version': 1,
  'body': 'cabin',
  'rows': [
    {
      'id': 'front',
      'seats': [
        {'id': 'fl', 'role': 'passenger', 'label': 'Front left'},
        {'id': 'fr', 'role': 'passenger', 'label': 'Front right'},
        {'id': 'drv', 'role': 'driver', 'label': 'Driver'},
      ],
    },
    {
      'id': 'back',
      'seats': [
        {'id': 'b1', 'role': 'passenger', 'label': 'Back left'},
        {'id': 'b2', 'role': 'passenger', 'label': 'Back middle left'},
        {'id': 'b3', 'role': 'passenger', 'label': 'Back middle right'},
        {'id': 'b4', 'role': 'passenger', 'label': 'Back right'},
      ],
    },
  ],
};
