import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // Backend API URL - Update this to your actual backend URL
  // static const String baseUrl = 'http://192.168.31.53:8000';
  static const String baseUrl = 'https://ai-expense.thankfulwater-706eddc2.centralindia.azurecontainerapps.io';

  // API Endpoints - Transactions
  static const String transactionsEndpoint = '/transactions';
  static const String uploadReceiptEndpoint = '/transactions/upload-receipt';
  static const String createTransactionEndpoint = '/transactions';
  static const String updateTransactionEndpoint = '/transactions'; // + /{id}
  static const String deleteTransactionEndpoint = '/transactions'; // + /{id}
  
  // API Endpoints - Splits
  static const String addSplitEndpoint = '/transactions/split';
  static const String updateSplitEndpoint = '/transactions/split';
  static const String deleteSplitEndpoint = '/transactions/split'; // + /{id}

  // API Endpoints - Events
  static const String eventsEndpoint = '/events';
  static const String addTransactionsToEventEndpoint = '/events/add_transactions';
  static const String removeTransactionsFromEventEndpoint = '/events/remove_transactions';
}

/// Transaction types
enum TransactionType {
  debit('DEBIT'),
  credit('CREDIT');

  final String value;
  const TransactionType(this.value);

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value.toUpperCase() == value.toUpperCase(),
      orElse: () => TransactionType.debit,
    );
  }
}

/// Transaction categories with their associated colors and icons
enum TransactionCategory {
  food('Food', Icons.restaurant, Color(0xFFFF6B6B)),
  travel('Travel', Icons.flight, Color(0xFF4ECDC4)),
  utilities('Utilities', Icons.bolt, Color(0xFFFFE66D)),
  transfer('Transfer', Icons.swap_horiz, Color(0xFF95E1D3)),
  shopping('Shopping', Icons.shopping_bag, Color(0xFFDDA0DD)),
  other('Other', Icons.category, Color(0xFFA8A8A8));

  final String label;
  final IconData icon;
  final Color color;

  const TransactionCategory(this.label, this.icon, this.color);

  static TransactionCategory fromString(String? value) {
    if (value == null) return TransactionCategory.other;
    return TransactionCategory.values.firstWhere(
      (e) => e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => TransactionCategory.other,
    );
  }
}
