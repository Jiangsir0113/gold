import 'package:flutter/material.dart';
import '../models/price_model.dart';

class PriceCard extends StatelessWidget {
  final String label;
  final String unit;
  final PriceData? data;
  final bool isStale;

  const PriceCard({
    super.key,
    required this.label,
    required this.unit,
    this.data,
    this.isStale = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = (data?.change ?? 0) >= 0;
    final color = isUp ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                if (isStale)
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            if (data == null)
              const Text('--', style: TextStyle(fontSize: 28))
            else ...[
              Text(
                '${data!.price.toStringAsFixed(2)} $unit',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                '${isUp ? '+' : ''}${data!.change.toStringAsFixed(2)}  '
                '${isUp ? '+' : ''}${data!.changePct.toStringAsFixed(2)}%',
                style: TextStyle(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
