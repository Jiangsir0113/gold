import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  int _reconnectSec = 30;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _urlCtrl.text = await AppConfig.getServerUrl();
    _keyCtrl.text = await AppConfig.getApiKey();
    _reconnectSec = await AppConfig.getReconnectSeconds();
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await AppConfig.saveSettings(
      serverUrl: _urlCtrl.text.trim(),
      apiKey: _keyCtrl.text.trim(),
      reconnectSeconds: _reconnectSec,
    );
    apiService.invalidateClient();
    websocketService.dispose();
    websocketService.connect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存，重新连接中…')),
      );
    }
  }

  void _exportCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请通过浏览器访问 /api/transactions/export 下载 CSV')),
    );
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: '服务器地址',
              hintText: 'http://your-server-ip',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            decoration: const InputDecoration(labelText: 'API Key'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          Text('断线重连间隔：$_reconnectSec 秒'),
          Slider(
            value: _reconnectSec.toDouble(),
            min: 10, max: 120, divisions: 11,
            label: '$_reconnectSec 秒',
            onChanged: (v) => setState(() => _reconnectSec = v.round()),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('保存设置')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _exportCsv,
            icon: const Icon(Icons.download),
            label: const Text('导出交易记录 CSV'),
          ),
        ],
      ),
    );
  }
}
