import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MiniChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const MiniChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(height: 80, child: Center(child: Text('暂无数据')));
    }

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['price'] as num).toDouble());
    }).toList();

    final prices = spots.map((s) => s.y).toList();
    final minY = prices.reduce((a, b) => a < b ? a : b) * 0.999;
    final maxY = prices.reduce((a, b) => a > b ? a : b) * 1.001;
    final isUp = spots.last.y >= spots.first.y;
    final lineColor = isUp ? Colors.red : Colors.green;

    return SizedBox(
      height: 80,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
