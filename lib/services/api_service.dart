import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/transaction_model.dart';
import '../models/summary_model.dart';

class ApiService {
  Dio? _dio;

  Future<Dio> _client() async {
    if (_dio != null) return _dio!;
    final baseUrl = await AppConfig.getServerUrl();
    final apiKey = await AppConfig.getApiKey();
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {'X-API-Key': apiKey},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    return _dio!;
  }

  void invalidateClient() => _dio = null;

  Future<List<Transaction>> getTransactions() async {
    final client = await _client();
    final resp = await client.get('/api/transactions');
    return (resp.data as List).map((e) => Transaction.fromJson(e)).toList();
  }

  Future<Transaction> createTransaction(Transaction tx) async {
    final client = await _client();
    final resp = await client.post('/api/transactions', data: tx.toJson());
    return Transaction.fromJson(resp.data);
  }

  Future<Transaction> updateTransaction(Transaction tx) async {
    final client = await _client();
    final resp = await client.put('/api/transactions/${tx.id}', data: tx.toJson());
    return Transaction.fromJson(resp.data);
  }

  Future<void> deleteTransaction(int id) async {
    final client = await _client();
    await client.delete('/api/transactions/$id');
  }

  Future<PositionSummary> getSummary() async {
    final client = await _client();
    final resp = await client.get('/api/summary');
    return PositionSummary.fromJson(resp.data);
  }

  Future<List<Map<String, dynamic>>> getSummaryHistory() async {
    final client = await _client();
    final resp = await client.get('/api/summary/history');
    return List<Map<String, dynamic>>.from(resp.data);
  }

  Future<List<Map<String, dynamic>>> getPriceHistory(String symbol) async {
    final client = await _client();
    final resp = await client.get('/api/prices/history', queryParameters: {'symbol': symbol});
    return List<Map<String, dynamic>>.from(resp.data['history']);
  }
}

final apiService = ApiService();
