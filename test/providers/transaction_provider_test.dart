import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gold_app/providers/transaction_provider.dart';

void main() {
  test('TransactionNotifier can be instantiated', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(transactionProvider), returnsNormally);
  });
}
