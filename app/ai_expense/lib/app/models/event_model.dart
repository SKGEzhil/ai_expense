import 'transaction_model.dart';

/// Event model matching the backend schema
class Event {
  final int? id;
  final String eventName;
  final String? eventNotes;
  final List<Transaction>? transactions;

  Event({
    this.id,
    required this.eventName,
    this.eventNotes,
    this.transactions,
  });

  /// Create Event from JSON (API response)
  factory Event.fromJson(Map<String, dynamic> json) {
    List<Transaction>? txns;
    if (json['transactions'] != null) {
      txns = (json['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList();
    }

    return Event(
      id: json['id'] as int?,
      eventName: json['event_name'] as String? ?? '',
      eventNotes: json['event_notes'] as String?,
      transactions: txns,
    );
  }

  /// Convert Event to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'event_name': eventName,
      'event_notes': eventNotes,
    };
  }

  /// Get total spent in this event (debits only)
  double get totalSpent {
    if (transactions == null) return 0;
    return transactions!
        .where((t) => t.isDebit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Get spending by category
  Map<String, double> get spendingByCategory {
    if (transactions == null) return {};
    final Map<String, double> result = {};
    for (final txn in transactions!.where((t) => t.isDebit)) {
      final category = txn.category ?? 'Other';
      result[category] = (result[category] ?? 0) + txn.amount;
    }
    return result;
  }

  /// Get transaction count
  int get transactionCount => transactions?.length ?? 0;

  /// Create a copy with modified fields
  Event copyWith({
    int? id,
    String? eventName,
    String? eventNotes,
    List<Transaction>? transactions,
  }) {
    return Event(
      id: id ?? this.id,
      eventName: eventName ?? this.eventName,
      eventNotes: eventNotes ?? this.eventNotes,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, eventName: $eventName, transactionCount: $transactionCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
