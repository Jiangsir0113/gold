import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _keyServerUrl = 'server_url';
  static const String _keyApiKey = 'api_key';
  static const String _keyReconnectInterval = 'reconnect_interval';

  static const String defaultServerUrl = 'http://49.233.160.10';
  static const String defaultApiKey = '';
  static const int defaultReconnectSeconds = 30;

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl) ?? defaultServerUrl;
  }

  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey) ?? defaultApiKey;
  }

  static Future<int> getReconnectSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReconnectInterval) ?? defaultReconnectSeconds;
  }

  static Future<void> saveSettings({
    String? serverUrl,
    String? apiKey,
    int? reconnectSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (serverUrl != null) await prefs.setString(_keyServerUrl, serverUrl);
    if (apiKey != null) await prefs.setString(_keyApiKey, apiKey);
    if (reconnectSeconds != null) await prefs.setInt(_keyReconnectInterval, reconnectSeconds);
  }

  static Future<String> wsUrl() async {
    final base = await getServerUrl();
    final key = await getApiKey();
    final wsBase = base.replaceFirst('http', 'ws');
    return '$wsBase/ws/prices?api_key=$key';
  }
}
