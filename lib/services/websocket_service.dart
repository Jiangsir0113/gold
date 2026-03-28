import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import '../models/price_model.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _controller = StreamController<PricesSnapshot>.broadcast();
  bool _isConnected = false;
  Timer? _reconnectTimer;

  Stream<PricesSnapshot> get priceStream => _controller.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    final wsUrl = await AppConfig.wsUrl();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      _reconnectTimer?.cancel();

      _channel!.stream.listen(
        (message) {
          try {
            final json = jsonDecode(message as String) as Map<String, dynamic>;
            if (json['type'] == 'price_update') {
              _controller.add(PricesSnapshot.fromJson(json));
            }
          } catch (_) {}
        },
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
      );
    } catch (_) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    _scheduleReconnect();
  }

  Future<void> _scheduleReconnect() async {
    final seconds = await AppConfig.getReconnectSeconds();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: seconds), connect);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}

final websocketService = WebSocketService();
