import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/event_model.dart';

/// Cache service for offline-first data loading
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _transactionsKey = 'cached_transactions';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const String _eventsKey = 'cached_events';
  static const String _eventsCacheTimestampKey = 'events_cache_timestamp';

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ============== TRANSACTIONS CACHE ==============

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

  /// Check if transactions cache exists
  Future<bool> hasTransactionsCache() async {
    await init();
    return _prefs?.containsKey(_transactionsKey) ?? false;
  }

  /// Clear transactions cache (called on refresh, search, add new transaction)
  Future<void> clearTransactionsCache() async {
    await init();
    await _prefs?.remove(_transactionsKey);
    await _prefs?.remove(_cacheTimestampKey);
  }

  // ============== EVENTS CACHE ==============

  /// Save events to cache
  Future<void> saveEvents(List<Event> events) async {
    await init();
    final jsonList = events.map((e) => e.toJson()).toList();
    await _prefs?.setString(_eventsKey, json.encode(jsonList));
    await _prefs?.setInt(_eventsCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Load events from cache
  Future<List<Event>> getEvents() async {
    await init();
    final jsonString = _prefs?.getString(_eventsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => Event.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if events cache exists
  Future<bool> hasEventsCache() async {
    await init();
    return _prefs?.containsKey(_eventsKey) ?? false;
  }

  /// Clear events cache
  Future<void> clearEventsCache() async {
    await init();
    await _prefs?.remove(_eventsKey);
    await _prefs?.remove(_eventsCacheTimestampKey);
  }

  // ============== LEGACY METHODS (for compatibility) ==============

  /// Check if cache exists (transactions)
  Future<bool> hasCache() async {
    return hasTransactionsCache();
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await clearTransactionsCache();
    await clearEventsCache();
  }
}
