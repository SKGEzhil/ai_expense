import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/theme.dart';
import 'transactions/transactions_view.dart';
import 'analytics/analytics_view.dart';
import 'events/events_view.dart';

/// Main home view with bottom navigation
class HomeView extends StatelessWidget {
  HomeView({super.key});

  final RxInt _currentIndex = 0.obs;

  final List<Widget> _pages = [
    const TransactionsView(),
    const EventsView(),
    const AnalyticsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() => IndexedStack(
            index: _currentIndex.value,
            children: _pages,
          )),
      bottomNavigationBar: Obx(() => Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                top: BorderSide(
                  color: AppTheme.dividerColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long,
                      label: 'Expenses',
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.event_outlined,
                      activeIcon: Icons.event,
                      label: 'Events',
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.pie_chart_outline,
                      activeIcon: Icons.pie_chart,
                      label: 'Analytics',
                    ),
                  ],
                ),
              ),
            ),
          )),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex.value == index;

    return GestureDetector(
      onTap: () => _currentIndex.value = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

