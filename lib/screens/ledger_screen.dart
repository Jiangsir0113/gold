import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/transaction_form.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  void _showForm(BuildContext context, WidgetRef ref, {Transaction? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionForm(
        existing: existing,
        onSubmit: (tx) async {
          final notifier = ref.read(transactionProvider.notifier);
          if (existing == null) {
            await notifier.add(tx);
          } else {
            await notifier.edit(tx);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确认吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(transactionProvider.notifier).remove(id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('账本')),
      body: txAsync.when(
        data: (txs) => txs.isEmpty
            ? const Center(child: Text('暂无交易记录，点击右下角添加'))
            : ListView.separated(
                itemCount: txs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) => TransactionTile(
                  tx: txs[i],
                  onEdit: () => _showForm(context, ref, existing: txs[i]),
                  onDelete: () => _confirmDelete(context, ref, txs[i].id),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
