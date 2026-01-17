import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/event_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

/// GetX Controller for managing events state
class EventController extends GetxController {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Observable state
  final RxList<Event> events = <Event>[].obs;
  final Rx<Event?> currentEvent = Rx<Event?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Selection mode for removing transactions from event
  final RxBool isSelectionMode = false.obs;
  final RxSet<int> selectedTransactionIds = <int>{}.obs;

  // Track if initial load is done (for caching logic)
  bool _initialLoadDone = false;

  @override
  void onInit() {
    super.onInit();
    fetchEvents();
  }

  /// Fetch all events from API (or cache if offline)
  Future<void> fetchEvents({bool forceRefresh = false}) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      // If not forcing refresh and we have cached data, use it
      if (!forceRefresh && _initialLoadDone && events.isNotEmpty) {
        isLoading.value = false;
        return;
      }

      // Try to fetch from API
      final result = await _apiService.getAllEvents();
      events.assignAll(result);
      _initialLoadDone = true;

      // Save to cache
      await _cacheService.saveEvents(result);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();

      // If network error and no data, try loading from cache
      if (events.isEmpty) {
        await _loadFromCache();
      }

      if (events.isEmpty) {
        Get.snackbar(
          'Error',
          'Failed to load events',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Load events from cache (fallback for offline)
  Future<void> _loadFromCache() async {
    try {
      final cached = await _cacheService.getEvents();
      if (cached.isNotEmpty) {
        events.assignAll(cached);
        Get.snackbar(
          'Offline Mode',
          'Showing cached events',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Refresh events (force fetch from API)
  Future<void> refreshEvents() async {
    await _cacheService.clearEventsCache();
    await fetchEvents(forceRefresh: true);
  }

  /// Fetch single event with transactions
  Future<void> fetchEventDetails(int eventId) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final result = await _apiService.getEvent(eventId);
      currentEvent.value = result;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load event details',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Create new event
  Future<Event?> createEvent(String name, String? notes) async {
    try {
      isLoading.value = true;

      final newEvent = Event(eventName: name, eventNotes: notes);
      final result = await _apiService.createEvent(newEvent);

      // Add to list
      events.add(result);

      // Invalidate cache
      await _cacheService.clearEventsCache();

      Get.snackbar(
        'Success',
        'Event created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      Get.back();
      return result;
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

  /// Delete event
  Future<bool> deleteEvent(int eventId) async {
    try {
      isLoading.value = true;
      final message = await _apiService.deleteEvent(eventId);

      // Remove from list
      events.removeWhere((e) => e.id == eventId);

      // Invalidate cache
      await _cacheService.clearEventsCache();

      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

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

  /// Add transactions to event
  Future<bool> addTransactionsToEvent(int eventId, List<int> txnIds) async {
    try {
      isLoading.value = true;
      final message = await _apiService.addTransactionsToEvent(eventId, txnIds);

      // Invalidate caches
      await _cacheService.clearCache();

      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

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

  /// Remove transactions from event
  Future<bool> removeTransactionsFromEvent(int eventId, List<int> txnIds) async {
    try {
      isLoading.value = true;
      final message = await _apiService.removeTransactionsFromEvent(eventId, txnIds);

      // Update current event if viewing
      if (currentEvent.value?.id == eventId) {
        final updatedTxns = currentEvent.value?.transactions
            ?.where((t) => !txnIds.contains(t.id))
            .toList();
        currentEvent.value = currentEvent.value?.copyWith(transactions: updatedTxns);
      }

      // Invalidate caches
      await _cacheService.clearCache();

      // Clear selection
      clearSelection();

      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

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

  // ============== SELECTION MODE ==============

  /// Toggle selection mode
  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedTransactionIds.clear();
    }
  }

  /// Toggle transaction selection
  void toggleSelection(int txnId) {
    if (selectedTransactionIds.contains(txnId)) {
      selectedTransactionIds.remove(txnId);
    } else {
      selectedTransactionIds.add(txnId);
    }

    // Exit selection mode if no items selected
    if (selectedTransactionIds.isEmpty) {
      isSelectionMode.value = false;
    }
  }

  /// Clear selection
  void clearSelection() {
    selectedTransactionIds.clear();
    isSelectionMode.value = false;
  }

  /// Check if transaction is selected
  bool isSelected(int txnId) {
    return selectedTransactionIds.contains(txnId);
  }
}
