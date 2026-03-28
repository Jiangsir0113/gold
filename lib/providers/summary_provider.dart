import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/summary_model.dart';
import '../services/api_service.dart';
import 'transaction_provider.dart';

final summaryProvider = FutureProvider<PositionSummary>((ref) async {
  ref.watch(transactionProvider);
  return apiService.getSummary();
});

final summaryHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return apiService.getSummaryHistory();
});
