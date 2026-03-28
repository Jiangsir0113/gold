import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isBuy = tx.type == 'buy';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isBuy ? Colors.red.shade100 : Colors.green.shade100,
        child: Text(isBuy ? '买' : '卖',
            style: TextStyle(color: isBuy ? Colors.red : Colors.green)),
      ),
      title: Text('${tx.grams.toStringAsFixed(2)} 克  ×  ${tx.pricePerG.toStringAsFixed(2)} 元/克'),
      subtitle: Text(
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}'
          '${tx.fee > 0 ? '  手续费 ${tx.fee.toStringAsFixed(2)}' : ''}'
          '${tx.note != null ? '  ${tx.note}' : ''}'),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('编辑')),
          PopupMenuItem(value: 'delete', child: Text('删除')),
        ],
      ),
    );
  }
}
