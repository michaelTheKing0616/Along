import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a repeated top up key credits once', () async {
    final wallet = FakeWalletRepository(
      initial: const WalletSummary(balance: 4200),
    );
    await wallet.topUp(amount: 2000, idempotencyKey: 'k1');
    final again = await wallet.topUp(amount: 2000, idempotencyKey: 'k1');
    expect(again.balance, 6200);
    expect(again.entries.single.kind, WalletEntryKind.topUp);
  });

  test('custom amounts are bounded', () {
    expect(validateTopUpAmount(null), 'empty');
    expect(validateTopUpAmount(50), 'tooSmall');
    expect(validateTopUpAmount(60000), 'tooLarge');
    expect(validateTopUpAmount(1500), isNull);
  });
}
