import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

/// GetX Controller for managing transactions state
class TransactionController extends GetxController {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Observable state
  final RxList<Transaction> transactions = <Transaction>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString currentPrompt = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreData = true.obs;
  final int pageSize = 50;

  // Mode tracking: true = using prompt search, false = fetching all transactions
  final RxBool isSearchMode = false.obs;

  // Default prompt for search mode
  static const String defaultPrompt = 'last 30 days';

  @override
  void onInit() {
    super.onInit();
    // Initially fetch all transactions (no prompt/filter)
    fetchAllTransactions();
  }

  /// Fetch all transactions from API (without prompt filter)
  Future<void> fetchAllTransactions({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMoreData.value = true;
      transactions.clear();
      // Clear cache on refresh
      await _cacheService.clearCache();
    }

    if (isLoading.value || isLoadingMore.value) return;

    try {
      if (transactions.isEmpty) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }
      hasError.value = false;
      errorMessage.value = '';

      final result = await _apiService.getAllTransactions(
        limit: pageSize,
        page: currentPage.value,
      );

      if (result.isEmpty) {
        hasMoreData.value = false;
      } else {
        if (refresh || currentPage.value == 1) {
          transactions.assignAll(result);
        } else {
          transactions.addAll(result);
        }
        currentPage.value++;
        
        // Check if we received less than pageSize, meaning no more data
        if (result.length < pageSize) {
          hasMoreData.value = false;
        }
      }

      // Save to cache after successful fetch (only first page in all mode)
      if (currentPage.value == 2 && !isSearchMode.value) {
        await _cacheService.saveTransactions(transactions.toList());
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      
      // If network error and we have no data, try loading from cache
      if (transactions.isEmpty) {
        await _loadFromCache();
      }
      
      if (transactions.isEmpty) {
        Get.snackbar(
          'Error',
          'Failed to load transactions',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Fetch transactions from API with prompt (search mode)
  Future<void> fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMoreData.value = true;
      transactions.clear();
      // Clear cache on refresh
      await _cacheService.clearCache();
    }

    if (isLoading.value || isLoadingMore.value) return;

    try {
      if (transactions.isEmpty) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }
      hasError.value = false;
      errorMessage.value = '';

      final result = await _apiService.getTransactions(
        limit: pageSize,
        page: currentPage.value,
        prompt: currentPrompt.value,
      );

      if (result.isEmpty) {
        hasMoreData.value = false;
      } else {
        if (refresh || currentPage.value == 1) {
          transactions.assignAll(result);
        } else {
          transactions.addAll(result);
        }
        currentPage.value++;
        
        // Check if we received less than pageSize, meaning no more data
        if (result.length < pageSize) {
          hasMoreData.value = false;
        }
      }

      // Save to cache after successful fetch (only first page with default prompt)
      if (currentPage.value == 2 && currentPrompt.value == defaultPrompt) {
        await _cacheService.saveTransactions(transactions.toList());
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      
      // If network error and we have no data, try loading from cache
      if (transactions.isEmpty) {
        await _loadFromCache();
      }
      
      if (transactions.isEmpty) {
        Get.snackbar(
          'Error',
          'Failed to load transactions',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Load transactions from cache (fallback for offline)
  Future<void> _loadFromCache() async {
    try {
      final cached = await _cacheService.getTransactions();
      if (cached.isNotEmpty) {
        transactions.assignAll(cached);
        hasMoreData.value = false; // Disable pagination for cached data
        Get.snackbar(
          'Offline Mode',
          'Showing cached transactions',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Load more transactions (pagination)
  Future<void> loadMore() async {
    if (hasMoreData.value && !isLoadingMore.value && !isLoading.value) {
      if (isSearchMode.value) {
        await fetchTransactions();
      } else {
        await fetchAllTransactions();
      }
    }
  }

  /// Refresh transactions
  Future<void> refreshTransactions() async {
    if (isSearchMode.value) {
      await fetchTransactions(refresh: true);
    } else {
      await fetchAllTransactions(refresh: true);
    }
  }

  /// Search with natural language prompt
  Future<void> searchWithPrompt(String prompt) async {
    isSearchMode.value = true;
    currentPrompt.value = prompt;
    // Clear cache when searching
    await _cacheService.clearCache();
    await fetchTransactions(refresh: true);
  }

  /// Clear search and return to all transactions
  Future<void> clearSearch() async {
    isSearchMode.value = false;
    currentPrompt.value = '';
    await fetchAllTransactions(refresh: true);
  }

  /// Upload receipt image
  Future<Transaction?> uploadReceipt(File imageFile) async {
    try {
      isLoading.value = true;
      final transaction = await _apiService.uploadReceipt(imageFile);
      
      // Add to list at the beginning
      transactions.insert(0, transaction);
      
      // Invalidate cache
      await _cacheService.clearCache();
      
      Get.snackbar(
        'Success',
        'Transaction added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return transaction;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Create transaction manually
  Future<Transaction?> createTransaction(Transaction transaction) async {
    try {
      isLoading.value = true;
      final result = await _apiService.createTransaction(transaction);
      
      // Add to list at the beginning
      transactions.insert(0, result.transaction);
      
      // Invalidate cache
      await _cacheService.clearCache();
      
      // Show server message
      Get.snackbar(
        'Success',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // Navigate back
      Get.back();
      
      return result.transaction;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update existing transaction
  Future<Transaction?> updateTransaction(int id, Transaction transaction) async {
    try {
      isLoading.value = true;
      final result = await _apiService.updateTransaction(id, transaction);
      
      // Update in list
      final index = transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        transactions[index] = result.transaction;
      }
      
      // Invalidate cache
      await _cacheService.clearCache();
      
      // Show server message
      Get.snackbar(
        'Success',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // Navigate back
      Get.back();
      
      return result.transaction;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      isLoading.value = true;
      final message = await _apiService.deleteTransaction(id);
      
      // Remove from list
      transactions.removeWhere((t) => t.id == id);
      
      // Invalidate cache
      await _cacheService.clearCache();
      
      // Show server message
      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // Navigate back
      Get.back();
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get total spent (debits only)
  double get totalSpent {
    return transactions
        .where((t) => t.isDebit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get total received (credits only)
  double get totalReceived {
    return transactions
        .where((t) => t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get transactions grouped by category
  Map<String, double> get spendingByCategory {
    final Map<String, double> result = {};
    for (final transaction in transactions.where((t) => t.isDebit)) {
      final category = transaction.category ?? 'Other';
      result[category] = (result[category] ?? 0) + transaction.amount;
    }
    return result;
  }
}
