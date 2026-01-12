import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

/// Cache service for offline-first transaction loading
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _transactionsKey = 'cached_transactions';
  static const String _cacheTimestampKey = 'cache_timestamp';

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save transactions to cache
  Future<void> saveTransactions(List<Transaction> transactions) async {
    await init();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await _prefs?.setString(_transactionsKey, json.encode(jsonList));
    await _prefs?.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Load transactions from cache
  Future<List<Transaction>> getTransactions() async {
    await init();
    final jsonString = _prefs?.getString(_transactionsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => Transaction.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if cache exists
  Future<bool> hasCache() async {
    await init();
    return _prefs?.containsKey(_transactionsKey) ?? false;
  }

  /// Clear cache (called on refresh, search, add new transaction)
  Future<void> clearCache() async {
    await init();
    await _prefs?.remove(_transactionsKey);
    await _prefs?.remove(_cacheTimestampKey);
  }
}
