import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/transaction_model.dart';

/// Time frame options for analytics
enum TimeFrame { thisWeek, last7Days, thisMonth, last30Days, custom }

/// Analysis mode - either time frame or custom prompt
enum AnalysisMode { timeFrame, prompt }

/// GetX Controller for managing analytics state
class AnalyticsController extends GetxController {
  final ApiService _apiService = ApiService();

  // Analysis mode
  final Rx<AnalysisMode> analysisMode = AnalysisMode.timeFrame.obs;

  // Time frame state
  final Rx<TimeFrame> selectedTimeFrame = TimeFrame.thisMonth.obs;
  final Rx<DateTime?> customStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> customEndDate = Rx<DateTime?>(null);

  // Loading and data state
  final RxBool isLoading = false.obs;
  final RxBool hasData = false.obs;
  final RxString currentPrompt = ''.obs;

  // Analytics data
  final RxList<Transaction> analyticsTransactions = <Transaction>[].obs;

  // Cache key prefix
  static const String _cacheKeyPrefix = 'analytics_cache_';

  /// Get prompt for time frame
  String _getPromptForTimeFrame(TimeFrame frame) {
    switch (frame) {
      case TimeFrame.thisWeek:
        return 'this week';
      case TimeFrame.last7Days:
        return 'last 7 days';
      case TimeFrame.thisMonth:
        return 'this month';
      case TimeFrame.last30Days:
        return 'last 30 days';
      case TimeFrame.custom:
        if (customStartDate.value != null && customEndDate.value != null) {
          final start = DateFormat('yyyy-MM-dd').format(customStartDate.value!);
          final end = DateFormat('yyyy-MM-dd').format(customEndDate.value!);
          return 'from $start to $end';
        }
        return 'last 30 days';
    }
  }

  /// Get date range for the selected time frame
  ({DateTime start, DateTime end}) _getDateRangeForTimeFrame(TimeFrame frame) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (frame) {
      case TimeFrame.thisWeek:
        // Start of current week (Monday)
        final weekday = today.weekday;
        final startOfWeek = today.subtract(Duration(days: weekday - 1));
        return (start: startOfWeek, end: today);
      case TimeFrame.last7Days:
        return (start: today.subtract(const Duration(days: 6)), end: today);
      case TimeFrame.thisMonth:
        return (start: DateTime(now.year, now.month, 1), end: today);
      case TimeFrame.last30Days:
        return (start: today.subtract(const Duration(days: 29)), end: today);
      case TimeFrame.custom:
        return (
          start: customStartDate.value ?? today.subtract(const Duration(days: 29)),
          end: customEndDate.value ?? today,
        );
    }
  }

  /// Analyse with time frame
  Future<void> analyseWithTimeFrame(TimeFrame frame) async {
    analysisMode.value = AnalysisMode.timeFrame;
    selectedTimeFrame.value = frame;
    final prompt = _getPromptForTimeFrame(frame);
    await _fetchData(prompt);
  }

  /// Analyse with custom prompt
  Future<void> analyseWithPrompt(String prompt) async {
    analysisMode.value = AnalysisMode.prompt;
    await _fetchData(prompt);
  }

  /// Set custom date range and analyse
  Future<void> setCustomDateRange(DateTime start, DateTime end) async {
    customStartDate.value = start;
    customEndDate.value = end;
    await analyseWithTimeFrame(TimeFrame.custom);
  }

  /// Fetch data with prompt
  Future<void> _fetchData(String prompt) async {
    if (isLoading.value) return;

    isLoading.value = true;
    currentPrompt.value = prompt;

    try {
      final transactions = await _apiService.getTransactions(
        limit: -1,
        page: 1,
        prompt: prompt,
      );

      analyticsTransactions.assignAll(transactions);
      hasData.value = true;
      await _saveToCache(prompt, transactions);
    } catch (e) {
      final cached = await _loadFromCache(prompt);
      if (cached.isNotEmpty) {
        analyticsTransactions.assignAll(cached);
        hasData.value = true;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear analysis and go back to initial state
  void clearAnalysis() {
    hasData.value = false;
    analyticsTransactions.clear();
    currentPrompt.value = '';
  }

  /// Refresh current analysis
  Future<void> refreshAnalysis() async {
    if (currentPrompt.value.isNotEmpty) {
      await _fetchData(currentPrompt.value);
    }
  }

  Future<void> _saveToCache(String prompt, List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKeyPrefix + prompt.hashCode.toString();
      final jsonList = transactions.map((t) => t.toJson()).toList();
      await prefs.setString(key, json.encode(jsonList));
    } catch (_) {}
  }

  Future<List<Transaction>> _loadFromCache(String prompt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKeyPrefix + prompt.hashCode.toString();
      final jsonString = prefs.getString(key);
      if (jsonString == null) return [];
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => Transaction.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  // === Computed analytics ===

  double get totalSpendingInRange {
    return analyticsTransactions
        .where((t) => t.isDebit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalIncome {
    return analyticsTransactions
        .where((t) => t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> get spendingByCategoryInRange {
    final Map<String, double> result = {};
    for (final t in analyticsTransactions.where((t) => t.isDebit)) {
      final category = t.category ?? 'Other';
      result[category] = (result[category] ?? 0) + t.amount;
    }
    return result;
  }

  List<CategoryData> get categoryData {
    final data = spendingByCategoryInRange;
    final total = data.values.fold(0.0, (sum, val) => sum + val);

    return data.entries.map((entry) {
      return CategoryData(
        category: entry.key,
        amount: entry.value,
        percentage: total > 0 ? (entry.value / total) * 100 : 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  String? get topCategory {
    if (categoryData.isEmpty) return null;
    return categoryData.first.category;
  }

  double get topCategoryAmount {
    if (categoryData.isEmpty) return 0;
    return categoryData.first.amount;
  }

  int get transactionCount => analyticsTransactions.length;
  int get debitCount => analyticsTransactions.where((t) => t.isDebit).length;
  int get creditCount => analyticsTransactions.where((t) => t.isCredit).length;

  ({double amount, DateTime? date, String? payee}) get highestSpending {
    final debits = analyticsTransactions.where((t) => t.isDebit).toList();
    if (debits.isEmpty) return (amount: 0, date: null, payee: null);
    final highest = debits.reduce((a, b) => a.amount > b.amount ? a : b);
    return (amount: highest.amount, date: highest.transactionDate, payee: highest.payee);
  }

  /// Get chart data with all days in range (including zero-spend days)
  List<DailySpending> get chartData {
    if (analysisMode.value == AnalysisMode.prompt) {
      // For prompt mode, just use the transaction dates
      return _getChartDataFromTransactions();
    }

    // For time frame mode, show all days in the range
    final range = _getDateRangeForTimeFrame(selectedTimeFrame.value);
    return _getChartDataForRange(range.start, range.end);
  }

  List<DailySpending> _getChartDataFromTransactions() {
    final transactions = analyticsTransactions.where((t) => t.isDebit).toList();
    if (transactions.isEmpty) return [];

    final Map<String, double> dailyTotals = {};
    for (final t in transactions) {
      if (t.transactionDate != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(t.transactionDate!);
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + t.amount;
      }
    }

    final sortedKeys = dailyTotals.keys.toList()..sort();
    return sortedKeys.map((key) {
      return DailySpending(date: DateTime.parse(key), amount: dailyTotals[key]!);
    }).toList();
  }

  List<DailySpending> _getChartDataForRange(DateTime start, DateTime end) {
    // Build a map of date -> total from transactions
    final Map<String, double> dailyTotals = {};
    for (final t in analyticsTransactions.where((t) => t.isDebit)) {
      if (t.transactionDate != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(t.transactionDate!);
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + t.amount;
      }
    }

    // Generate all days in range
    final List<DailySpending> result = [];
    var current = start;
    while (!current.isAfter(end)) {
      final dateKey = DateFormat('yyyy-MM-dd').format(current);
      result.add(DailySpending(
        date: current,
        amount: dailyTotals[dateKey] ?? 0,
      ));
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  double get chartTotal => chartData.fold(0.0, (sum, d) => sum + d.amount);

  double get chartAverage {
    if (chartData.isEmpty) return 0;
    final nonZeroDays = chartData.where((d) => d.amount > 0).length;
    if (nonZeroDays == 0) return 0;
    return chartTotal / nonZeroDays;
  }

  String get timeFrameLabel {
    if (analysisMode.value == AnalysisMode.prompt) {
      return 'Custom Query';
    }
    switch (selectedTimeFrame.value) {
      case TimeFrame.thisWeek:
        return 'This Week';
      case TimeFrame.last7Days:
        return 'Last 7 Days';
      case TimeFrame.thisMonth:
        return 'This Month';
      case TimeFrame.last30Days:
        return 'Last 30 Days';
      case TimeFrame.custom:
        return 'Custom Range';
    }
  }
}

class CategoryData {
  final String category;
  final double amount;
  final double percentage;

  CategoryData({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class DailySpending {
  final DateTime date;
  final double amount;

  DailySpending({
    required this.date,
    required this.amount,
  });
}
