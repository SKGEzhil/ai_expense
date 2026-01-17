import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/event_controller.dart';
import '../../models/event_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../transactions/transaction_detail_view.dart';

/// Event detail view showing stats and transactions
class EventDetailView extends StatefulWidget {
  final int eventId;

  const EventDetailView({super.key, required this.eventId});

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  late EventController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<EventController>();
    _controller.clearSelection();
    // Clear and load fresh data
    _controller.currentEvent.value = null;
    _controller.isLoading.value = true;
    _controller.fetchEventDetails(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            controller.clearSelection();
            Get.back();
          },
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        ),
        title: Obx(() => Text(
              controller.currentEvent.value?.eventName ?? 'Event',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            )),
        actions: [
          Obx(() {
            if (controller.isSelectionMode.value) {
              return TextButton(
                onPressed: () => controller.clearSelection(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              );
            }
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
              color: AppTheme.surfaceColor,
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation(controller);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
                      SizedBox(width: 8),
                      Text('Delete Event', style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        // Show loading state
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        // Show error state
        if (controller.hasError.value && controller.currentEvent.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
                const SizedBox(height: 16),
                const Text('Failed to load event', style: TextStyle(color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Text(controller.errorMessage.value, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.fetchEventDetails(widget.eventId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final event = controller.currentEvent.value;
        if (event == null) {
          return const Center(
            child: Text('Event not found', style: TextStyle(color: AppTheme.textMuted)),
          );
        }

        final transactions = event.transactions ?? [];
        final isEmpty = transactions.isEmpty;

        return RefreshIndicator(
          onRefresh: () => controller.fetchEventDetails(widget.eventId),
          child: CustomScrollView(
            slivers: [
              // Stats Header
              SliverToBoxAdapter(
                child: _buildStatsHeader(event),
              ),

              // Transactions section title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions (${transactions.length})',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (transactions.isNotEmpty && !controller.isSelectionMode.value)
                        TextButton.icon(
                          onPressed: () => controller.toggleSelectionMode(),
                          icon: const Icon(Icons.checklist, size: 18),
                          label: const Text('Select'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Empty state
              if (isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: AppTheme.textMuted,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add transactions from the Expenses tab',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

              // Transactions list
              if (!isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildTransactionItem(
                        transactions[index],
                        controller,
                      ),
                      childCount: transactions.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        if (controller.isSelectionMode.value && controller.selectedTransactionIds.isNotEmpty) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(top: BorderSide(color: AppTheme.dividerColor.withOpacity(0.5))),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _removeSelectedTransactions(controller),
              icon: const Icon(Icons.remove_circle_outline),
              label: Text('Remove ${controller.selectedTransactionIds.length} from Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildStatsHeader(Event event) {
    final spendingByCategory = event.spendingByCategory;
    final totalSpent = event.totalSpent;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total spent
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_down,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Spent',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '₹${totalSpent.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (spendingByCategory.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(color: AppTheme.dividerColor),
            const SizedBox(height: 16),

            // Category chart
            const Text(
              'By Category',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Pie chart
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  // Chart
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(spendingByCategory, totalSpent),
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Legend
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: spendingByCategory.entries.map((entry) {
                        final category = TransactionCategory.fromString(entry.key);
                        final percentage = (entry.value / totalSpent * 100).toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: category.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category.label,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '$percentage%',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category amounts
            ...spendingByCategory.entries.map((entry) {
              final category = TransactionCategory.fromString(entry.key);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.label,
                        style: TextStyle(
                          color: category.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '₹${entry.value.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: category.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
      Map<String, double> spendingByCategory, double total) {
    return spendingByCategory.entries.map((entry) {
      final category = TransactionCategory.fromString(entry.key);
      final percentage = entry.value / total * 100;
      return PieChartSectionData(
        color: category.color,
        value: entry.value,
        title: percentage >= 10 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 35,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildTransactionItem(Transaction txn, EventController controller) {
    final category = TransactionCategory.fromString(txn.category);
    final isSelected = controller.isSelected(txn.id!);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (controller.isSelectionMode.value) {
            controller.toggleSelection(txn.id!);
          } else {
            Get.to(() => TransactionDetailView(transaction: txn));
          }
        },
        onLongPress: () {
          if (!controller.isSelectionMode.value) {
            controller.toggleSelectionMode();
          }
          controller.toggleSelection(txn.id!);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Selection checkbox or category icon
              if (controller.isSelectionMode.value)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                    size: 24,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 4),
                    Text(
                      txn.transactionDate != null
                          ? DateFormat('MMM d, yyyy').format(txn.transactionDate!)
                          : '',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
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
      ),
    );
  }

  void _removeSelectedTransactions(EventController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Remove Transactions',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Remove ${controller.selectedTransactionIds.length} transaction(s) from this event?',
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
              controller.removeTransactionsFromEvent(
                widget.eventId,
                controller.selectedTransactionIds.toList(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(EventController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Delete Event',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this event? '
          'Transactions will not be deleted, just unlinked from the event.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteEvent(widget.eventId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
