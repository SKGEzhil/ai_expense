import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../controllers/analytics_controller.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/prompt_bar.dart';

/// Analytics dashboard view
class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AnalyticsController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Obx(() {
          if (!controller.hasData.value && !controller.isLoading.value) {
            return _buildInitialState(context, controller);
          }

          if (controller.isLoading.value) {
            return _buildLoadingState();
          }

          return _buildAnalyticsContent(context, controller);
        }),
      ),
    );
  }

  Widget _buildInitialState(BuildContext context, AnalyticsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: AppTheme.primaryColor,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analytics',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how to analyze your spending',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),

          // Option 1: Time Frame
          _buildOptionCard(
            title: 'By Time Frame',
            subtitle: 'Analyze spending for a specific period',
            icon: Icons.calendar_today,
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildTimeFrameGrid(context, controller),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'OR',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Option 2: Custom Prompt
          _buildOptionCard(
            title: 'By Custom Query',
            subtitle: 'Ask anything about your spending',
            icon: Icons.auto_awesome,
            child: Column(
              children: [
                const SizedBox(height: 12),
                PromptBar(
                  onSubmit: (prompt) => controller.analyseWithPrompt(prompt),
                  onClear: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
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
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildTimeFrameGrid(BuildContext context, AnalyticsController controller) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTimeChip('This Week', TimeFrame.thisWeek, controller),
        _buildTimeChip('Last 7 Days', TimeFrame.last7Days, controller),
        _buildTimeChip('This Month', TimeFrame.thisMonth, controller),
        _buildTimeChip('Last 30 Days', TimeFrame.last30Days, controller),
        _buildCustomRangeChip(context, controller),
      ],
    );
  }

  Widget _buildTimeChip(String label, TimeFrame frame, AnalyticsController controller) {
    return GestureDetector(
      onTap: () => controller.analyseWithTimeFrame(frame),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRangeChip(BuildContext context, AnalyticsController controller) {
    return GestureDetector(
      onTap: () => _showDateRangePicker(context, controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, color: AppTheme.textMuted, size: 16),
            SizedBox(width: 6),
            Text(
              'Custom Range',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'Analyzing your spending...',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, AnalyticsController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshAnalysis(),
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with clear button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your spending insights',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => controller.refreshAnalysis(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => controller.clearAnalysis(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppTheme.errorColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show appropriate selector based on mode
            Obx(() => controller.analysisMode.value == AnalysisMode.timeFrame
                ? _buildActiveTimeFrameSelector(context, controller)
                : _buildActivePromptBar(controller)),
            const SizedBox(height: 20),

            // Total Spent Card
            _buildTotalSpentCard(controller),
            const SizedBox(height: 24),

            // Spending Over Time (moved above category)
            _buildSectionTitle('Spending Over Time'),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildChart(controller)),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildChartInfo(controller)),
              ],
            ),
            const SizedBox(height: 24),

            // Spending by Category
            _buildSectionTitle('Spending by Category'),
            const SizedBox(height: 16),
            _buildCategoryChart(controller),
            const SizedBox(height: 16),
            _buildCategoryLegend(controller),
            const SizedBox(height: 24),

            // Quick Stats
            _buildSectionTitle('Quick Stats'),
            const SizedBox(height: 16),
            _buildQuickStats(controller),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTimeFrameSelector(BuildContext context, AnalyticsController controller) {
    return Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActiveTimeChip('This Week', TimeFrame.thisWeek, controller),
              const SizedBox(width: 8),
              _buildActiveTimeChip('Last 7 Days', TimeFrame.last7Days, controller),
              const SizedBox(width: 8),
              _buildActiveTimeChip('This Month', TimeFrame.thisMonth, controller),
              const SizedBox(width: 8),
              _buildActiveTimeChip('Last 30 Days', TimeFrame.last30Days, controller),
              const SizedBox(width: 8),
              _buildActiveCustomRangeChip(context, controller),
            ],
          ),
        ));
  }

  Widget _buildActiveTimeChip(String label, TimeFrame frame, AnalyticsController controller) {
    final isSelected = controller.selectedTimeFrame.value == frame;
    return GestureDetector(
      onTap: () => controller.analyseWithTimeFrame(frame),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCustomRangeChip(BuildContext context, AnalyticsController controller) {
    final isSelected = controller.selectedTimeFrame.value == TimeFrame.custom;
    return GestureDetector(
      onTap: () => _showDateRangePicker(context, controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              color: isSelected ? Colors.white : AppTheme.textMuted,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Custom',
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePromptBar(AnalyticsController controller) {
    return PromptBar(
      currentPrompt: controller.currentPrompt.value,
      onSubmit: (prompt) => controller.analyseWithPrompt(prompt),
      onClear: () => controller.clearAnalysis(),
    );
  }

  void _showDateRangePicker(BuildContext context, AnalyticsController controller) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: controller.customStartDate.value ?? now.subtract(const Duration(days: 30)),
        end: controller.customEndDate.value ?? now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.surfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setCustomDateRange(picked.start, picked.end);
    }
  }

  Widget _buildTotalSpentCard(AnalyticsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.errorColor.withOpacity(0.15),
            AppTheme.errorColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_upward, color: AppTheme.errorColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Spent',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  Obx(() => Text(
                        controller.timeFrameLabel,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => Text(
                '₹${controller.totalSpendingInRange.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildChart(AnalyticsController controller) {
    return Obx(() {
      final data = controller.chartData;
      final maxAmount = data.map((e) => e.amount).fold(0.0, (a, b) => a > b ? a : b);

      if (data.isEmpty) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('No spending data', style: TextStyle(color: AppTheme.textMuted)),
          ),
        );
      }

      final showLabels = data.length <= 7;

      return Container(
        height: showLabels ? 220 : 200,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxAmount > 0 ? maxAmount * 1.2 : 100,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => AppTheme.surfaceColor,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final index = group.x.toInt();
                  if (index >= 0 && index < data.length) {
                    final d = data[index];
                    return BarTooltipItem(
                      '${DateFormat('MMM d').format(d.date)}\n₹${d.amount.toStringAsFixed(0)}',
                      const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: showLabels,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: showLabels,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < data.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('E').format(data[index].date),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((entry) {
              double barWidth;
              if (data.length <= 7) {
                barWidth = 20;
              } else if (data.length <= 15) {
                barWidth = 10;
              } else {
                barWidth = 5;
              }

              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.amount,
                    color: entry.value.amount > 0
                        ? AppTheme.primaryColor
                        : AppTheme.dividerColor,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildChartInfo(AnalyticsController controller) {
    return Obx(() {
      final highest = controller.highestSpending;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('Total', '₹${controller.chartTotal.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            _buildInfoItem('Avg/day', '₹${controller.chartAverage.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Highest',
              '₹${highest.amount.toStringAsFixed(0)}',
              subtitle: highest.date != null ? DateFormat('MMM d').format(highest.date!) : null,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInfoItem(String label, String value, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
      ],
    );
  }

  Widget _buildCategoryChart(AnalyticsController controller) {
    return Obx(() {
      final data = controller.categoryData;

      if (data.isEmpty) {
        return Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('No spending data', style: TextStyle(color: AppTheme.textMuted)),
          ),
        );
      }

      return Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 35,
            sections: data.map((categoryData) {
              final category = TransactionCategory.fromString(categoryData.category);
              return PieChartSectionData(
                color: category.color,
                value: categoryData.amount,
                title: '${categoryData.percentage.toStringAsFixed(0)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildCategoryLegend(AnalyticsController controller) {
    return Obx(() {
      final data = controller.categoryData;

      return Wrap(
        spacing: 16,
        runSpacing: 10,
        children: data.map((categoryData) {
          final category = TransactionCategory.fromString(categoryData.category);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '${category.label}: ₹${categoryData.amount.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          );
        }).toList(),
      );
    });
  }

  Widget _buildQuickStats(AnalyticsController controller) {
    return Obx(() => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            children: [
              _buildStatRow('Total Transactions', controller.transactionCount.toString(), Icons.receipt_long),
              if (controller.topCategory != null) ...[
                const Divider(color: AppTheme.dividerColor, height: 24),
                _buildStatRow(
                  'Top Category',
                  controller.topCategory!,
                  TransactionCategory.fromString(controller.topCategory).icon,
                  color: TransactionCategory.fromString(controller.topCategory).color,
                ),
              ],
            ],
          ),
        ));
  }

  Widget _buildStatRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.primaryColor).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? AppTheme.primaryColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ),
        Text(
          value,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
