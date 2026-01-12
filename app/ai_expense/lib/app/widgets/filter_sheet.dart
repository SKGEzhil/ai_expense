import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';

/// Time frame options for filter
enum FilterTimeFrame { thisWeek, last7Days, thisMonth, last30Days, custom }

/// Bottom sheet for advanced filtering options
class FilterSheet extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedType;
  final Function(String prompt) onApply;

  const FilterSheet({
    super.key,
    this.startDate,
    this.endDate,
    this.selectedType,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String _selectedType;
  FilterTimeFrame? _selectedTimeFrame;
  bool _showCustomDatePickers = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedType = widget.selectedType ?? 'ALL';
    _selectedTimeFrame = FilterTimeFrame.thisMonth; // Default
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
      _selectedType = 'ALL';
      _selectedTimeFrame = FilterTimeFrame.thisMonth;
      _showCustomDatePickers = false;
    });
  }

  void _apply() {
    // Build prompt from filter settings
    final List<String> promptParts = [];

    // Type part
    if (_selectedType == 'DEBIT') {
      promptParts.add('debit transactions');
    } else if (_selectedType == 'CREDIT') {
      promptParts.add('credit transactions');
    } else {
      promptParts.add('both credit and debit transactions');
    }

    // Time frame part
    switch (_selectedTimeFrame) {
      case FilterTimeFrame.thisWeek:
        promptParts.add('this week');
        break;
      case FilterTimeFrame.last7Days:
        promptParts.add('last 7 days');
        break;
      case FilterTimeFrame.thisMonth:
        promptParts.add('this month');
        break;
      case FilterTimeFrame.last30Days:
        promptParts.add('last 30 days');
        break;
      case FilterTimeFrame.custom:
        if (_startDate != null && _endDate != null) {
          final start = DateFormat('yyyy-MM-dd').format(_startDate!);
          final end = DateFormat('yyyy-MM-dd').format(_endDate!);
          promptParts.add('from $start to $end');
        } else if (_startDate != null) {
          final start = DateFormat('yyyy-MM-dd').format(_startDate!);
          promptParts.add('from $start');
        } else if (_endDate != null) {
          final end = DateFormat('yyyy-MM-dd').format(_endDate!);
          promptParts.add('until $end');
        }
        break;
      default:
        break;
    }

    final prompt = promptParts.join(' ');
    widget.onApply(prompt);
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

          // Transaction Type
          const Text(
            'Transaction Type',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TypeChip(
                label: 'All',
                isSelected: _selectedType == 'ALL',
                onTap: () => setState(() => _selectedType = 'ALL'),
              ),
              const SizedBox(width: 12),
              _TypeChip(
                label: 'Debit',
                isSelected: _selectedType == 'DEBIT',
                onTap: () => setState(() => _selectedType = 'DEBIT'),
                color: AppTheme.errorColor,
              ),
              const SizedBox(width: 12),
              _TypeChip(
                label: 'Credit',
                isSelected: _selectedType == 'CREDIT',
                onTap: () => setState(() => _selectedType = 'CREDIT'),
                color: AppTheme.successColor,
              ),
            ],
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

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.2) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? chipColor : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
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
