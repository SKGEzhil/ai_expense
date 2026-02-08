import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/event_controller.dart';
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
                          // Show selection count when in selection mode
                          if (controller.isSelectionMode.value)
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => controller.clearSelection(),
                                  icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                                ),
                                Text(
                                  '${controller.selectedTransactionIds.length} selected',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else
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
                          if (!controller.isSelectionMode.value)
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

                  // Active search/filter indicator
                  SliverToBoxAdapter(
                    child: Obx(() {
                      // Check for prompt search
                      if (controller.isSearchMode.value &&
                          !controller.isDateRangeMode.value &&
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
                                  'Search: "${controller.currentPrompt.value}"',
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
                      // Check for date range filter
                      if (controller.isSearchMode.value &&
                          controller.isDateRangeMode.value &&
                          controller.currentDateRange.value.isNotEmpty) {
                        // Format the date range for display (dd-MM-yyyy,dd-MM-yyyy -> human readable)
                        final parts = controller.currentDateRange.value.split(',');
                        String displayText = controller.currentDateRange.value;
                        if (parts.length == 2) {
                          displayText = '${parts[0]} to ${parts[1]}';
                        }
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
                                Icons.date_range,
                                color: AppTheme.primaryLight,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Filter: $displayText',
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
      floatingActionButton: Obx(() {
        if (controller.isSelectionMode.value && controller.selectedTransactionIds.isNotEmpty) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddToEventSheet(context, controller),
            icon: const Icon(Icons.event),
            label: const Text('Add to Event'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          );
        }
        return FloatingActionButton.extended(
          onPressed: () => _openAddTransaction(),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        );
      }),
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
          ...group.transactions.map((txn) => _buildTransactionItem(txn, Get.find<TransactionController>())),
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

  Widget _buildTransactionItem(Transaction txn, TransactionController controller) {
    final category = TransactionCategory.fromString(txn.category);
    final isSelected = txn.id != null && controller.isSelected(txn.id!);
    final isSelectionMode = controller.isSelectionMode.value;

    return InkWell(
      onTap: () {
        if (isSelectionMode) {
          if (txn.id != null) controller.toggleSelection(txn.id!);
        } else {
          Get.to(() => TransactionDetailView(transaction: txn));
        }
      },
      onLongPress: () {
        if (!isSelectionMode) {
          controller.toggleSelectionMode();
        }
        if (txn.id != null) controller.toggleSelection(txn.id!);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 0.5)),
        ),
        child: Row(
          children: [
            // Selection checkbox or Category icon
            if (isSelectionMode)
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                  size: 22,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.icon, color: category.color, size: 18),
              ),
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
        onApply: (dateRange) {
          if (dateRange != null && dateRange.isNotEmpty) {
            controller.filterByDateRange(dateRange);
          } else {
            // No filter selected - show all transactions
            controller.clearSearch();
          }
        },
      ),
    );
  }

  void _openAddTransaction() {
    Get.to(() => const AddTransactionView());
  }

  void _showAddToEventSheet(BuildContext context, TransactionController txnController) {
    final eventController = Get.find<EventController>();
    // Refresh events to get latest list
    eventController.fetchEvents();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Obx(() {
          final events = eventController.events;
          final isLoading = eventController.isLoading.value;

          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add to Event',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${txnController.selectedTransactionIds.length} transaction(s) selected',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                // Loading state
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  ),

                // Empty state
                if (!isLoading && events.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.event,
                            color: AppTheme.textMuted,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No events yet',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create an event first from the Events tab',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Events list
                if (!isLoading && events.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return ListTile(
                          onTap: () async {
                            Navigator.pop(context);
                            await txnController.addSelectedToEvent(event.id!);
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.event,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            event.eventName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: event.eventNotes != null && event.eventNotes!.isNotEmpty
                              ? Text(
                                  event.eventNotes!,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppTheme.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Model for date grouped transactions
class DateGroup {
  final DateTime? date;
  final List<Transaction> transactions;

  DateGroup({required this.date, required this.transactions});
}
