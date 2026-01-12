import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import 'add_transaction_view.dart';

/// Transaction detail view with edit/delete options
class TransactionDetailView extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailView({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final category = TransactionCategory.fromString(transaction.category);
    final isDebit = transaction.isDebit;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
        ),
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            onPressed: () => _editTransaction(),
            icon: const Icon(Icons.edit, color: AppTheme.primaryLight),
          ),
          IconButton(
            onPressed: () => _showDeleteConfirmation(context),
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Amount Card with left/right layout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDebit
                      ? [
                          AppTheme.errorColor.withOpacity(0.15),
                          AppTheme.errorColor.withOpacity(0.05),
                        ]
                      : [
                          AppTheme.successColor.withOpacity(0.15),
                          AppTheme.successColor.withOpacity(0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDebit
                      ? AppTheme.errorColor.withOpacity(0.3)
                      : AppTheme.successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side: Amount and Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          transaction.formattedAmount,
                          style: TextStyle(
                            color: isDebit ? AppTheme.errorColor : AppTheme.successColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDebit
                              ? AppTheme.errorColor.withOpacity(0.2)
                              : AppTheme.successColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isDebit ? 'DEBIT' : 'CREDIT',
                          style: TextStyle(
                            color: isDebit ? AppTheme.errorColor : AppTheme.successColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Right side: Notes, Payee, Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notes (if exists)
                        if (transaction.notes?.isNotEmpty == true) ...[
                          Text(
                            transaction.notes!,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                        ],
                        // Payee
                        if (transaction.payee != null)
                          Text(
                            transaction.payee!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: category.color.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category.icon,
                                color: category.color,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category.label,
                                style: TextStyle(
                                  color: category.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 20),

            // Other Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Details',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Date', transaction.formattedDate),
                  if (transaction.transactionTime != null) ...[
                    _buildDivider(),
                    _buildDetailRow('Time', transaction.transactionTime!),
                  ],
                  if (transaction.sourceApp != null) ...[
                    _buildDivider(),
                    _buildDetailRow('Source App', transaction.sourceApp!),
                  ],
                  if (transaction.bankAccount != null) ...[
                    _buildDivider(),
                    _buildDetailRow('Bank Account', transaction.bankAccount!),
                  ],
                  if (transaction.upiTransactionId != null) ...[
                    _buildDivider(),
                    _buildDetailRow('UPI ID', transaction.upiTransactionId!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: AppTheme.dividerColor,
      height: 1,
    );
  }

  void _editTransaction() {
    Get.to(() => AddTransactionView(editTransaction: transaction));
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Transaction?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (transaction.id != null) {
                final success = await Get.find<TransactionController>()
                    .deleteTransaction(transaction.id!);
                if (success) {
                  Get.back();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
