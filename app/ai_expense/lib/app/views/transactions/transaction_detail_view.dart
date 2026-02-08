import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/split_model.dart' as models;
import '../../models/transaction_model.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import 'add_transaction_view.dart';

/// Transaction detail view with edit/delete options and split management
class TransactionDetailView extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailView({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailView> createState() => _TransactionDetailViewState();
}

class _TransactionDetailViewState extends State<TransactionDetailView> {
  final ApiService _apiService = ApiService();
  late Transaction _transaction;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
    final category = TransactionCategory.fromString(_transaction.category);
    final isDebit = _transaction.isDebit;

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
          // Add Split button
          IconButton(
            onPressed: () => _showAddSplitDialog(),
            icon: const Icon(Icons.call_split, color: AppTheme.primaryLight),
            tooltip: 'Add Split',
          ),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Amount Card with left/right layout
                _buildAmountCard(isDebit, category),

                const SizedBox(height: 20),

                // Transaction Details Card
                _buildDetailsCard(),

                const SizedBox(height: 20),

                // Splits Section
                _buildSplitsSection(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(bool isDebit, TransactionCategory category) {
    return Container(
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
                  _transaction.formattedAmount,
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
                if (_transaction.notes?.isNotEmpty == true) ...[
                  Text(
                    _transaction.notes!,
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
                if (_transaction.payee != null)
                  Text(
                    _transaction.payee!,
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
    );
  }

  Widget _buildDetailsCard() {
    return Container(
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
          _buildDetailRow('Date', _transaction.formattedDate),
          if (_transaction.transactionTime != null) ...[
            _buildDivider(),
            _buildDetailRow('Time', _transaction.transactionTime!),
          ],
          if (_transaction.sourceApp != null) ...[
            _buildDivider(),
            _buildDetailRow('Source App', _transaction.sourceApp!),
          ],
          if (_transaction.bankAccount != null) ...[
            _buildDivider(),
            _buildDetailRow('Bank Account', _transaction.bankAccount!),
          ],
          if (_transaction.upiTransactionId != null) ...[
            _buildDivider(),
            _buildDetailRow('UPI ID', _transaction.upiTransactionId!),
          ],
        ],
      ),
    );
  }

  Widget _buildSplitsSection() {
    final splits = _transaction.splits;
    final totalSplitAmount = splits.fold<double>(0, (sum, s) => sum + s.amount);
    final settledAmount = splits.where((s) => s.isSettled).fold<double>(0, (sum, s) => sum + s.amount);

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Splits',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (splits.isNotEmpty)
                Text(
                  '₹$settledAmount / ₹$totalSplitAmount settled',
                  style: TextStyle(
                    color: settledAmount == totalSplitAmount 
                        ? AppTheme.successColor 
                        : AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (splits.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.call_split,
                    color: AppTheme.textMuted.withOpacity(0.5),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No splits yet',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddSplitDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Split'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: splits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildSplitItem(splits[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildSplitItem(models.Split split) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: split.isSettled 
            ? AppTheme.successColor.withOpacity(0.1) 
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: split.isSettled 
              ? AppTheme.successColor.withOpacity(0.3) 
              : AppTheme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: split.isSettled 
                  ? AppTheme.successColor.withOpacity(0.2)
                  : AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                split.payee.isNotEmpty ? split.payee[0].toUpperCase() : '?',
                style: TextStyle(
                  color: split.isSettled 
                      ? AppTheme.successColor 
                      : AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and notes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      split.payee,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        decoration: split.isSettled 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                    if (split.isSettled) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                if (split.notes != null && split.notes!.isNotEmpty)
                  Text(
                    split.notes!,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Amount
          Text(
            '₹${split.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: split.isSettled 
                  ? AppTheme.successColor 
                  : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
            color: AppTheme.surfaceColor,
            onSelected: (action) {
              switch (action) {
                case 'edit':
                  _showEditSplitDialog(split);
                  break;
                case 'settle':
                  _settleSplit(split);
                  break;
                case 'delete':
                  _showDeleteSplitConfirmation(split);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: AppTheme.textSecondary),
                    SizedBox(width: 8),
                    Text('Edit', style: TextStyle(color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              if (!split.isSettled)
                const PopupMenuItem(
                  value: 'settle',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: AppTheme.successColor),
                      SizedBox(width: 8),
                      Text('Settle', style: TextStyle(color: AppTheme.textPrimary)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
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

  // ==================== DIALOGS ====================

  void _showAddSplitDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Split',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(color: AppTheme.textPrimary),
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                validator: (v) {
                  if (v?.isEmpty == true) return 'Amount is required';
                  if (double.tryParse(v!) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _addSplit(
                  nameController.text,
                  double.parse(amountController.text),
                  notesController.text.isEmpty ? null : notesController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSplitDialog(models.Split split) {
    final nameController = TextEditingController(text: split.payee);
    final amountController = TextEditingController(text: split.amount.toString());
    final notesController = TextEditingController(text: split.notes ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Split',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(color: AppTheme.textPrimary),
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                validator: (v) {
                  if (v?.isEmpty == true) return 'Amount is required';
                  if (double.tryParse(v!) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (!split.isSettled)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _settleSplit(split);
              },
              child: const Text(
                'Settle',
                style: TextStyle(color: AppTheme.successColor),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _updateSplit(
                  split.id!,
                  nameController.text,
                  double.parse(amountController.text),
                  notesController.text.isEmpty ? null : notesController.text,
                  split.isSettled
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSplitConfirmation(models.Split split) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Split?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Remove split for ${split.payee}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSplit(split.id!);
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

  // ==================== API CALLS ====================

  Future<void> _addSplit(String payee, double amount, String? notes) async {
    if (_transaction.id == null) return;

    setState(() => _isLoading = true);
    try {
      final message = await _apiService.addSplit(
        txnId: _transaction.id!,
        payee: payee,
        amount: amount,
        notes: notes,
      );
      
      // Immediately update local state with new split
      final newSplit = models.Split(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        transactionId: _transaction.id,
        payee: payee,
        amount: amount,
        isSettled: false,
        notes: notes,
      );
      
      setState(() {
        _transaction = _transaction.copyWith(
          splits: [..._transaction.splits, newSplit],
        );
      });
      
      Get.snackbar('Success', message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSplit(int splitId, String payee, double amount, String? notes, bool isSettled) async {
    setState(() => _isLoading = true);
    try {
      final message = await _apiService.updateSplit(
        splitId: splitId,
        payee: payee,
        amount: amount,
        notes: notes,
        isSettled: isSettled,
      );
      
      // Immediately update local state
      setState(() {
        final updatedSplits = _transaction.splits.map((s) {
          if (s.id == splitId) {
            return s.copyWith(
              payee: payee,
              amount: amount,
              notes: notes,
              isSettled: isSettled,
            );
          }
          return s;
        }).toList();
        
        _transaction = _transaction.copyWith(splits: updatedSplits);
      });
      
      Get.snackbar('Success', message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _settleSplit(models.Split split) async {
    if (split.id == null) return;

    setState(() => _isLoading = true);
    try {
      final message = await _apiService.updateSplit(
        splitId: split.id!,
        payee: split.payee,
        amount: split.amount,
        notes: split.notes,
        isSettled: true,
      );
      
      // Immediately update local state
      setState(() {
        final updatedSplits = _transaction.splits.map((s) {
          if (s.id == split.id) {
            return s.copyWith(isSettled: true);
          }
          return s;
        }).toList();
        
        _transaction = _transaction.copyWith(splits: updatedSplits);
      });
      
      Get.snackbar('Success', message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSplit(int splitId) async {
    setState(() => _isLoading = true);
    try {
      final message = await _apiService.deleteSplit(splitId);
      
      // Immediately update local state
      setState(() {
        final updatedSplits = _transaction.splits
            .where((s) => s.id != splitId)
            .toList();
        
        _transaction = _transaction.copyWith(splits: updatedSplits);
      });
      
      Get.snackbar('Success', message, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editTransaction() {
    Get.to(() => AddTransactionView(editTransaction: _transaction));
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
              if (_transaction.id != null) {
                final success = await Get.find<TransactionController>()
                    .deleteTransaction(_transaction.id!);
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
