import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_model.dart';
import '../services/websocket_service.dart';

final priceProvider = StreamProvider<PricesSnapshot>((ref) {
  websocketService.connect();
  ref.onDispose(websocketService.dispose);
  return websocketService.priceStream;
});

final wsConnectedProvider = Provider<bool>((ref) {
  return websocketService.isConnected;
});
