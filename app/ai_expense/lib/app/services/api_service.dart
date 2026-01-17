import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/transaction_model.dart';
import '../models/event_model.dart';
import '../utils/constants.dart';
import 'settings_service.dart';

/// API Service for backend communication
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Get base URL dynamically from settings
  String get baseUrl => _settingsService?.baseUrl ?? 'http://localhost:8000';

  SettingsService? _settingsService;

  /// Initialize with settings service
  Future<void> init() async {
    _settingsService = await SettingsService.getInstance();
  }

  /// Headers for JSON requests
  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// GET /transactions - Fetch transactions with optional prompt
  Future<List<Transaction>> getTransactions({
    int limit = 20,
    int page = 1,
    String prompt = '',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.transactionsEndpoint}').replace(
        queryParameters: {
          'lim': limit.toString(),
          'page': page.toString(),
          'prompt': prompt,
        },
      );

      final response = await http.get(uri, headers: _jsonHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to fetch transactions',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// GET /transactions/all - Fetch all transactions without prompt (for initial load)
  Future<List<Transaction>> getAllTransactions({
    int limit = 50,
    int page = 1,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.allTransactionsEndpoint}').replace(
        queryParameters: {
          'lim': limit.toString(),
          'page': page.toString(),
        },
      );

      final response = await http.get(uri, headers: _jsonHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to fetch all transactions',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// POST /upload-receipt - Upload screenshot for extraction
  Future<Transaction> uploadReceipt(File imageFile) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.uploadReceiptEndpoint}');

      final request = http.MultipartRequest('POST', uri);
      
      // Get file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if it was a duplicate
        if (data['status'] == 'skipped') {
          throw ApiException(data['message'] ?? 'Transaction already exists');
        }
        
        return Transaction.fromJson(data);
      } else {
        throw ApiException(
          'Failed to upload receipt',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// POST /transactions - Create transaction manually
  Future<({Transaction transaction, String message})> createTransaction(Transaction transaction) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.createTransactionEndpoint}');

      final response = await http.post(
        uri,
        headers: _jsonHeaders,
        body: json.encode(transaction.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final txn = Transaction.fromJson(data['transaction'] ?? data);
        final message = data['message'] ?? 'Transaction created successfully';
        return (transaction: txn, message: message.toString());
      } else {
        final errorMessage = _extractErrorMessage(response.body) ?? 'Failed to create transaction';
        throw ApiException(errorMessage, statusCode: response.statusCode, body: response.body);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// PUT /transactions/{id} - Update transaction
  Future<({Transaction transaction, String message})> updateTransaction(int id, Transaction transaction) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.updateTransactionEndpoint}/$id');

      final response = await http.put(
        uri,
        headers: _jsonHeaders,
        body: json.encode(transaction.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final txn = Transaction.fromJson(data['transaction'] ?? data);
        final message = data['message'] ?? 'Transaction updated successfully';
        return (transaction: txn, message: message.toString());
      } else {
        final errorMessage = _extractErrorMessage(response.body) ?? 'Failed to update transaction';
        throw ApiException(errorMessage, statusCode: response.statusCode, body: response.body);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// DELETE /transactions/{id} - Delete transaction
  Future<String> deleteTransaction(int id) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.deleteTransactionEndpoint}/$id');

      final response = await http.delete(uri, headers: _jsonHeaders);

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isNotEmpty) {
          final data = json.decode(response.body);
          return data['message'] ?? 'Transaction deleted successfully';
        }
        return 'Transaction deleted successfully';
      } else {
        final errorMessage = _extractErrorMessage(response.body) ?? 'Failed to delete transaction';
        throw ApiException(errorMessage, statusCode: response.statusCode, body: response.body);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Extract error message from response body
  String? _extractErrorMessage(String body) {
    try {
      final data = json.decode(body);
      return data['message'] ?? data['error'] ?? data['detail'];
    } catch (_) {
      return null;
    }
  }

  // ============== EVENTS API ==============

  /// GET /events - Fetch all events
  Future<List<Event>> getAllEvents() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.eventsEndpoint}/');
      final response = await http.get(uri, headers: _jsonHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to fetch events',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// GET /events/{id} - Fetch single event with transactions
  Future<Event> getEvent(int eventId) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.eventsEndpoint}/$eventId');
      final response = await http.get(uri, headers: _jsonHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Event.fromJson(data);
      } else {
        throw ApiException(
          'Failed to fetch event',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// POST /events - Create new event
  Future<Event> createEvent(Event event) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.eventsEndpoint}/');
      final response = await http.post(
        uri,
        headers: _jsonHeaders,
        body: json.encode(event.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Event.fromJson(data);
      } else {
        final errorMessage = _extractErrorMessage(response.body) ?? 'Failed to create event';
        throw ApiException(errorMessage, statusCode: response.statusCode, body: response.body);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// PUT /events - Update event
  Future<void> updateEvent(Event event) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.eventsEndpoint}');
      final response = await http.put(
        uri,
        headers: _jsonHeaders,
        body: json.encode(event.toJson()),
      );

      if (response.statusCode != 200) {
        final errorMessage = _extractErrorMessage(response.body) ?? 'Failed to update event';
        throw ApiException(errorMessage, statusCode: response.statusCode, body: response.body);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// DELETE /events/{id} - Delete event
  Future<String> deleteEvent(int eventId) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.eventsEndpoint}/$eventId');
      final response = await http.delete(uri, headers: _jsonHeaders);

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.isNotEmpty) {
          final data = json.decode(response.body);
          return data['message'] ?? 'Event deleted successfully';
        }
        return 'Event deleted successfully';
      } else {
        final errorMessage = _extractErrorMessage(response.body) ?? 'Failed to delete event';
        throw ApiException(errorMessage, statusCode: response.statusCode, body: response.body);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// POST /events/add_transactions - Add transactions to event
  Future<String> addTransactionsToEvent(int eventId, List<int> txnIds) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.addTransactionsToEventEndpoint}');
      final response = await http.post(
        uri,
        headers: _jsonHeaders,
        body: json.encode({
          'event_id': eventId,
          'txn_ids': txnIds,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] ?? 'Transactions added successfully';
      } else {
        final errorMessage = _extractErrorMessage(response.body) ?? 'Failed to add transactions';
        throw ApiException(errorMessage, statusCode: response.statusCode, body: response.body);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// POST /events/remove_transactions - Remove transactions from event
  Future<String> removeTransactionsFromEvent(int eventId, List<int> txnIds) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.removeTransactionsFromEventEndpoint}');
      final response = await http.post(
        uri,
        headers: _jsonHeaders,
        body: json.encode({
          'event_id': eventId,
          'txn_ids': txnIds,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] ?? 'Transactions removed successfully';
      } else {
        final errorMessage = _extractErrorMessage(response.body) ?? 'Failed to remove transactions';
        throw ApiException(errorMessage, statusCode: response.statusCode, body: response.body);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status: $statusCode)';
    }
    return 'ApiException: $message';
  }
}
