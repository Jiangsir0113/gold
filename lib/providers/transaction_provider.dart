import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() => apiService.getTransactions();

  Future<void> add(Transaction tx) async {
    await apiService.createTransaction(tx);
    ref.invalidateSelf();
  }

  Future<void> edit(Transaction tx) async {
    await apiService.updateTransaction(tx);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await apiService.deleteTransaction(id);
    ref.invalidateSelf();
  }
}

final transactionProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(TransactionNotifier.new);
