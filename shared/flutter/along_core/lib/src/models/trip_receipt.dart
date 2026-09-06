import 'package:along_core/src/formatting/money_format.dart';
import 'package:along_core/src/value/money.dart';

/// Itemised fare breakdown for R-22 / R-27 receipts.
class TripReceipt {
  const TripReceipt({
    required this.fare,
    this.surcharge,
    this.commission,
    required this.total,
  });

  final Money fare;
  final Money? surcharge;
  final Money? commission;
  final Money total;

  List<TripReceiptLine> get lines {
    final items = <TripReceiptLine>[
      TripReceiptLine(label: 'Fare', amount: fare),
    ];
    if (surcharge != null && surcharge!.minorUnits > 0) {
      items.add(TripReceiptLine(label: 'Load surcharge', amount: surcharge!));
    }
    if (commission != null && commission!.minorUnits > 0) {
      items.add(TripReceiptLine(label: 'Along fee', amount: commission!));
    }
    return items;
  }

  String toShareText({
    required String routeLabel,
    required String driverName,
    required String plate,
  }) {
    final buffer = StringBuffer('Along trip receipt\n');
    buffer.writeln(routeLabel);
    buffer.writeln('Driver: $driverName · $plate');
    for (final line in lines) {
      buffer.writeln('${line.label}: ${formatMoney(line.amount)}');
    }
    buffer.write('Total: ${formatMoney(total)}');
    return buffer.toString();
  }
}

class TripReceiptLine {
  const TripReceiptLine({required this.label, required this.amount});

  final String label;
  final Money amount;
}
