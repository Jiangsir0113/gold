import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/summary_provider.dart';
import '../widgets/pnl_chart.dart';

class PositionScreen extends ConsumerWidget {
  const PositionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryProvider);
    final historyAsync = ref.watch(summaryHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('持仓'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(summaryProvider),
          )
        ],
      ),
      body: summaryAsync.when(
        data: (summary) {
          final isProfit = summary.unrealizedPnl >= 0;
          final pnlColor = isProfit ? Colors.red : Colors.green;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoRow('总持仓', '${summary.totalGrams.toStringAsFixed(4)} 克'),
              _InfoRow('买入均价', '${summary.avgCostPerG.toStringAsFixed(2)} 元/克'),
              _InfoRow('当前价格', '${summary.currentPrice.toStringAsFixed(2)} 元/克'),
              _InfoRow('当前市值', '${summary.marketValue.toStringAsFixed(2)} 元'),
              const Divider(),
              _InfoRow(
                '浮动盈亏',
                '${isProfit ? '+' : ''}${summary.unrealizedPnl.toStringAsFixed(2)} 元'
                    '  (${isProfit ? '+' : ''}${summary.unrealizedPnlPct.toStringAsFixed(2)}%)',
                valueColor: pnlColor,
              ),
              _InfoRow('已实现盈亏',
                  '${summary.realizedPnl >= 0 ? '+' : ''}${summary.realizedPnl.toStringAsFixed(2)} 元',
                  valueColor: summary.realizedPnl >= 0 ? Colors.red : Colors.green),
              _InfoRow('总盈亏',
                  '${summary.totalPnl >= 0 ? '+' : ''}${summary.totalPnl.toStringAsFixed(2)} 元',
                  valueColor: summary.totalPnl >= 0 ? Colors.red : Colors.green),
              const SizedBox(height: 16),
              Text('持仓市值历史', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              historyAsync.when(
                data: (history) => PnlChart(history: history),
                loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(height: 60, child: Center(child: Text('历史数据加载失败'))),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
              )),
        ],
      ),
    );
  }
}
