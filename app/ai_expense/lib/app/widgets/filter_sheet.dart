import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';

/// Time frame options for filter
enum FilterTimeFrame { thisWeek, last7Days, thisMonth, last30Days, custom }

/// Bottom sheet for advanced filtering options
class FilterSheet extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String? dateRange) onApply;

  const FilterSheet({
    super.key,
    this.startDate,
    this.endDate,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  FilterTimeFrame? _selectedTimeFrame;
  bool _showCustomDatePickers = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedTimeFrame = null; // No default - shows all transactions
  }

  void _selectTimeFrame(FilterTimeFrame frame) {
    setState(() {
      _selectedTimeFrame = frame;
      _showCustomDatePickers = frame == FilterTimeFrame.custom;
      if (frame != FilterTimeFrame.custom) {
        _startDate = null;
        _endDate = null;
      }
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
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
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _reset() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedTimeFrame = null;
      _showCustomDatePickers = false;
    });
  }

  void _apply() {
    // Build date range from filter settings
    String? dateRange;

    if (_selectedTimeFrame != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime startDate;
      DateTime endDate = today;

      switch (_selectedTimeFrame) {
        case FilterTimeFrame.thisWeek:
          // Start of current week (Monday)
          final weekday = today.weekday;
          startDate = today.subtract(Duration(days: weekday - 1));
          break;
        case FilterTimeFrame.last7Days:
          startDate = today.subtract(const Duration(days: 6));
          break;
        case FilterTimeFrame.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case FilterTimeFrame.last30Days:
          startDate = today.subtract(const Duration(days: 29));
          break;
        case FilterTimeFrame.custom:
          if (_startDate != null && _endDate != null) {
            startDate = _startDate!;
            endDate = _endDate!;
          } else {
            // If custom but dates not set, return null (all transactions)
            widget.onApply(null);
            Navigator.pop(context);
            return;
          }
          break;
        default:
          widget.onApply(null);
          Navigator.pop(context);
          return;
      }

      // Format as dd-MM-yyyy,dd-MM-yyyy
      final startStr = DateFormat('dd-MM-yyyy').format(startDate);
      final endStr = DateFormat('dd-MM-yyyy').format(endDate);
      dateRange = '$startStr,$endStr';
    }

    widget.onApply(dateRange);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Filter Expenses',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Time Frame
          const Text(
            'Time Frame',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Show All option
          _TimeChip(
            label: 'Show All',
            isSelected: _selectedTimeFrame == null,
            onTap: () => setState(() {
              _selectedTimeFrame = null;
              _showCustomDatePickers = false;
            }),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TimeChip(
                label: 'This Week',
                isSelected: _selectedTimeFrame == FilterTimeFrame.thisWeek,
                onTap: () => _selectTimeFrame(FilterTimeFrame.thisWeek),
              ),
              _TimeChip(
                label: 'Last 7 Days',
                isSelected: _selectedTimeFrame == FilterTimeFrame.last7Days,
                onTap: () => _selectTimeFrame(FilterTimeFrame.last7Days),
              ),
              _TimeChip(
                label: 'This Month',
                isSelected: _selectedTimeFrame == FilterTimeFrame.thisMonth,
                onTap: () => _selectTimeFrame(FilterTimeFrame.thisMonth),
              ),
              _TimeChip(
                label: 'Last 30 Days',
                isSelected: _selectedTimeFrame == FilterTimeFrame.last30Days,
                onTap: () => _selectTimeFrame(FilterTimeFrame.last30Days),
              ),
              _TimeChip(
                label: 'Custom Range',
                icon: Icons.date_range,
                isSelected: _selectedTimeFrame == FilterTimeFrame.custom,
                onTap: () => _selectTimeFrame(FilterTimeFrame.custom),
              ),
            ],
          ),

          // Custom Date Range Pickers
          if (_showCustomDatePickers) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'From',
                    date: _startDate,
                    onTap: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: 'To',
                    date: _endDate,
                    onTap: () => _selectDate(false),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.dividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _apply,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}



class _TimeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _TimeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textMuted,
                size: 14,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
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
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppTheme.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    date != null
                        ? DateFormat('MMM d, yyyy').format(date!)
                        : 'Select',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
