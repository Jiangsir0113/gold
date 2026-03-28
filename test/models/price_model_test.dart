import 'package:flutter_test/flutter_test.dart';
import 'package:gold_app/models/price_model.dart';

void main() {
  group('PriceData.fromJson', () {
    test('parses correctly', () {
      final json = {
        'price': 765.5,
        'change': 2.3,
        'change_pct': 0.3,
        'updated_at': '2026-03-28T10:00:00',
      };
      final pd = PriceData.fromJson(json);
      expect(pd.price, 765.5);
      expect(pd.changePct, 0.3);
    });
  });

  group('PricesSnapshot.fromJson', () {
    test('parses WebSocket message', () {
      final json = {
        'type': 'price_update',
        'data': {
          'au9999': {'price': 765.5, 'change': 2.3, 'change_pct': 0.3, 'updated_at': '2026-03-28T10:00:00'},
          'xauusd': {'price': 3012.5, 'change': -1.2, 'change_pct': -0.04, 'updated_at': '2026-03-28T10:00:00'},
          'usdcny': {'price': 7.2531, 'updated_at': '2026-03-28T10:00:00'},
        }
      };
      final snap = PricesSnapshot.fromJson(json);
      expect(snap.au9999!.price, 765.5);
      expect(snap.usdcny, 7.2531);
    });
  });
}
