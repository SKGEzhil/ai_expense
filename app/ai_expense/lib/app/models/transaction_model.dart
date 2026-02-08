import 'package:intl/intl.dart';
import 'split_model.dart';

/// Transaction model matching the backend schema
class Transaction {
  final int? id;
  final String txnType;
  final double amount;
  final String? payee;
  final String? category;
  final DateTime? transactionDate;
  final String? transactionTime;
  final String? sourceApp;
  final String? upiTransactionId;
  final String? bankAccount;
  final String? notes;
  final int? eventId;
  final List<Split> splits;

  Transaction({
    this.id,
    required this.txnType,
    required this.amount,
    this.payee,
    this.category,
    this.transactionDate,
    this.transactionTime,
    this.sourceApp,
    this.upiTransactionId,
    this.bankAccount,
    this.notes,
    this.eventId,
    this.splits = const [],
  });

  /// Create Transaction from JSON (API response)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Parse splits array if present
    List<Split> splits = [];
    if (json['splits'] != null && json['splits'] is List) {
      splits = (json['splits'] as List)
          .map((s) => Split.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return Transaction(
      id: json['id'] as int?,
      txnType: json['txn_type'] as String? ?? 'DEBIT',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      payee: json['payee'] as String?,
      category: json['category'] as String?,
      transactionDate: _parseDate(json['transaction_date']),
      transactionTime: json['transaction_time'] as String?,
      sourceApp: json['source_app'] as String?,
      upiTransactionId: json['upi_transaction_id'] as String?,
      bankAccount: json['bank_account'] as String?,
      notes: json['notes'] as String?,
      eventId: json['event_id'] as int?,
      splits: splits,
    );
  }

  /// Convert Transaction to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'txn_type': txnType,
      'amount': amount,
      'payee': payee,
      'category': category,
      'transaction_date': transactionDate != null
          ? DateFormat('yyyy-MM-dd').format(transactionDate!)
          : null,
      'transaction_time': transactionTime,
      'source_app': sourceApp,
      'upi_transaction_id': upiTransactionId,
      'bank_account': bankAccount,
      'notes': notes,
      if (eventId != null) 'event_id': eventId,
    };
  }

  /// Parse date from various formats
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Check if this is a debit transaction
  bool get isDebit => txnType.toUpperCase() == 'DEBIT';

  /// Check if this is a credit transaction
  bool get isCredit => txnType.toUpperCase() == 'CREDIT';

  /// Formatted amount string with sign
  String get formattedAmount {
    final sign = isDebit ? '-' : '+';
    return '$sign₹${amount.toStringAsFixed(2)}';
  }

  /// Formatted date string
  String get formattedDate {
    if (transactionDate == null) return 'Unknown date';
    return DateFormat('MMM dd, yyyy').format(transactionDate!);
  }

  /// Formatted time string
  String get formattedTime {
    return transactionTime ?? '';
  }

  /// Create a copy with modified fields
  Transaction copyWith({
    int? id,
    String? txnType,
    double? amount,
    String? payee,
    String? category,
    DateTime? transactionDate,
    String? transactionTime,
    String? sourceApp,
    String? upiTransactionId,
    String? bankAccount,
    String? notes,
    int? eventId,
    List<Split>? splits,
  }) {
    return Transaction(
      id: id ?? this.id,
      txnType: txnType ?? this.txnType,
      amount: amount ?? this.amount,
      payee: payee ?? this.payee,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionTime: transactionTime ?? this.transactionTime,
      sourceApp: sourceApp ?? this.sourceApp,
      upiTransactionId: upiTransactionId ?? this.upiTransactionId,
      bankAccount: bankAccount ?? this.bankAccount,
      notes: notes ?? this.notes,
      eventId: eventId ?? this.eventId,
      splits: splits ?? this.splits,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, txnType: $txnType, amount: $amount, payee: $payee)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
