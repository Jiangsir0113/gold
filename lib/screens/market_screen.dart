import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/price_provider.dart';
import '../services/api_service.dart';
import '../widgets/price_card.dart';
import '../widgets/mini_chart.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  List<Map<String, dynamic>> _au9999History = [];
  List<Map<String, dynamic>> _xauusdHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final au = await apiService.getPriceHistory('au9999');
      final xa = await apiService.getPriceHistory('xauusd');
      if (mounted) setState(() { _au9999History = au; _xauusdHistory = xa; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final priceAsync = ref.watch(priceProvider);
    final isConnected = ref.watch(wsConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('行情'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.circle,
              color: isConnected ? Colors.green : Colors.red,
              size: 12,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          children: [
            priceAsync.when(
              data: (snap) => Column(children: [
                PriceCard(label: 'AU9999 国内金价', unit: '元/克', data: snap.au9999),
                MiniChart(history: _au9999History),
                const SizedBox(height: 8),
                PriceCard(label: '伦敦金 XAU/USD', unit: 'USD/盎司', data: snap.xauusd),
                MiniChart(history: _xauusdHistory),
                if (snap.usdcny != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text('USD/CNY 参考汇率：${snap.usdcny!.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
              ]),
              loading: () => const Center(
                  heightFactor: 5, child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('连接失败：$e')),
            ),
          ],
        ),
      ),
    );
  }
}
