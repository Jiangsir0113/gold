import 'package:flutter_test/flutter_test.dart';
import 'package:gold_app/models/transaction_model.dart';

void main() {
  group('Transaction.toJson', () {
    test('serializes correctly for POST body', () {
      final tx = Transaction(
        id: 0,
        date: DateTime(2026, 3, 28),
        type: 'buy',
        grams: 10.5,
        pricePerG: 765.5,
        fee: 5.0,
        note: '测试',
      );
      final json = tx.toJson();
      expect(json['date'], '2026-03-28');
      expect(json['type'], 'buy');
      expect(json['grams'], 10.5);
      expect(json['price_per_g'], 765.5);
      expect(json['fee'], 5.0);
      expect(json['note'], '测试');
    });

    test('date is zero-padded', () {
      final tx = Transaction(
        id: 0,
        date: DateTime(2026, 1, 5),
        type: 'sell',
        grams: 5.0,
        pricePerG: 800.0,
        fee: 0.0,
      );
      expect(tx.toJson()['date'], '2026-01-05');
    });
  });

  group('Transaction.fromJson', () {
    test('parses API response correctly', () {
      final json = {
        'id': 42,
        'date': '2026-03-28',
        'type': 'buy',
        'grams': 10.0,
        'price_per_g': 700.0,
        'fee': 5.0,
        'note': null,
        'created_at': '2026-03-28T10:00:00',
      };
      final tx = Transaction.fromJson(json);
      expect(tx.id, 42);
      expect(tx.date.year, 2026);
      expect(tx.note, null);
    });
  });
}
