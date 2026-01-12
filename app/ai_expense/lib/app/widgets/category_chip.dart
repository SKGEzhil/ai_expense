import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// Colored chip widget for category display
class CategoryChip extends StatelessWidget {
  final TransactionCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? category.color.withOpacity(0.3) 
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? category.color : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              color: isSelected ? category.color : AppTheme.textMuted,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                color: isSelected ? category.color : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick filter chips row
class CategoryFilterRow extends StatelessWidget {
  final Set<String> selectedCategories;
  final Function(String) onToggle;

  const CategoryFilterRow({
    super.key,
    required this.selectedCategories,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: TransactionCategory.values.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              category: category,
              isSelected: selectedCategories.contains(category.label),
              onTap: () => onToggle(category.label),
            ),
          );
        }).toList(),
      ),
    );
  }
}
