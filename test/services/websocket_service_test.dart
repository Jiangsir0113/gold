import 'package:flutter_test/flutter_test.dart';
import 'package:gold_app/services/websocket_service.dart';

void main() {
  group('WebSocketService', () {
    test('isConnected is false before connect()', () {
      final service = WebSocketService();
      expect(service.isConnected, false);
      service.dispose();
    });

    test('priceStream is a broadcast stream', () {
      final service = WebSocketService();
      expect(service.priceStream.isBroadcast, true);
      service.dispose();
    });

    test('dispose closes stream without error', () {
      final service = WebSocketService();
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
