import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PnlChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const PnlChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('持仓数据不足，每日收盘后生成快照')),
      );
    }

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['market_value'] as num).toDouble());
    }).toList();

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.02;

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (v, _) =>
                    Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFB8860B),
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFB8860B).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
