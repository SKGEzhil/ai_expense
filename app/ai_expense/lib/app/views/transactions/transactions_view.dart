import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../widgets/prompt_bar.dart';
import '../../widgets/filter_sheet.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../settings/settings_view.dart';
import 'transaction_detail_view.dart';
import 'add_transaction_view.dart';

/// Main expenses list view with date grouping and full scroll
class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final TransactionController controller = Get.find<TransactionController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Obx(() {
          // Group transactions by date
          final groupedTransactions = _groupByDate(controller.transactions);
          final isLoading = controller.isLoading.value && controller.transactions.isEmpty;
          final hasError = controller.hasError.value && controller.transactions.isEmpty;
          final isEmpty = controller.transactions.isEmpty && !isLoading && !hasError;

          return RefreshIndicator(
            onRefresh: () => controller.refreshTransactions(),
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.surfaceColor,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 200) {
                  controller.loadMore();
                }
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expenses',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Track your expenses',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Settings button
                              IconButton(
                                onPressed: () => Get.to(() => const SettingsView()),
                                icon: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.dividerColor),
                                  ),
                                  child: const Icon(
                                    Icons.settings,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              // Filter button
                              IconButton(
                                onPressed: () => _showFilterSheet(context, controller),
                                icon: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.dividerColor),
                                  ),
                                  child: const Icon(
                                    Icons.tune,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Prompt Bar
                  SliverToBoxAdapter(
                    child: PromptBar(
                      currentPrompt: controller.currentPrompt.value,
                      onSubmit: (prompt) => controller.searchWithPrompt(prompt),
                      onClear: () => controller.clearSearch(),
                    ),
                  ),

                  // Active search indicator
                  SliverToBoxAdapter(
                    child: Obx(() {
                      if (controller.isSearchMode.value &&
                          controller.currentPrompt.value.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: AppTheme.primaryLight,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Filter: "${controller.currentPrompt.value}"',
                                  style: const TextStyle(
                                    color: AppTheme.primaryLight,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => controller.clearSearch(),
                                child: const Icon(
                                  Icons.close,
                                  color: AppTheme.primaryLight,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ),

                  // Loading state
                  if (isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      ),
                    ),

                  // Error state
                  if (hasError)
                    SliverFillRemaining(
                      child: _buildErrorState(controller),
                    ),

                  // Empty state
                  if (isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    ),

                  // Transactions list
                  if (controller.transactions.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= groupedTransactions.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            return _buildDateGroup(groupedTransactions[index]);
                          },
                          childCount: groupedTransactions.length +
                              (controller.isLoadingMore.value ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransaction(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Group transactions by date
  List<DateGroup> _groupByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};

    for (final txn in transactions) {
      final dateKey = txn.transactionDate != null
          ? DateFormat('yyyy-MM-dd').format(txn.transactionDate!)
          : 'Unknown';
      grouped.putIfAbsent(dateKey, () => []).add(txn);
    }

    // Sort by date descending
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((key) {
      final txns = grouped[key]!;
      DateTime? date;
      try {
        date = DateTime.parse(key);
      } catch (_) {}
      return DateGroup(date: date, transactions: txns);
    }).toList();
  }

  /// Build a date group widget
  Widget _buildDateGroup(DateGroup group) {
    // Calculate net for the day
    double netSpent = 0;
    for (final txn in group.transactions) {
      if (txn.isDebit) {
        netSpent -= txn.amount;
      } else {
        netSpent += txn.amount;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateHeader(group.date),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${netSpent >= 0 ? '+' : ''}₹${netSpent.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    color: netSpent >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Transactions
          ...group.transactions.map((txn) => _buildTransactionItem(txn)),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txnDate = DateTime(date.year, date.month, date.day);

    if (txnDate == today) return 'Today';
    if (txnDate == yesterday) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(date);
  }

  Widget _buildTransactionItem(Transaction txn) {
    final category = TransactionCategory.fromString(txn.category);

    return InkWell(
      onTap: () => Get.to(() => TransactionDetailView(transaction: txn)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, color: category.color, size: 18),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.notes?.isNotEmpty == true ? txn.notes! : (txn.payee ?? 'Transaction'),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (txn.payee != null && txn.notes?.isNotEmpty == true) ...[
                        Text(
                          txn.payee!,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category.label,
                          style: TextStyle(
                            color: category.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${txn.isDebit ? '-' : '+'}₹${txn.amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: txn.isDebit ? AppTheme.errorColor : AppTheme.successColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppTheme.textMuted,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No expenses found',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first expense to get started',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TransactionController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off,
                color: AppTheme.errorColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to load expenses',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.refreshTransactions(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, TransactionController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        onApply: (prompt) {
          controller.searchWithPrompt(prompt);
        },
      ),
    );
  }

  void _openAddTransaction() {
    Get.to(() => const AddTransactionView());
  }
}

/// Model for date grouped transactions
class DateGroup {
  final DateTime? date;
  final List<Transaction> transactions;

  DateGroup({required this.date, required this.transactions});
}
