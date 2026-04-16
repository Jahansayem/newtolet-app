import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/property_filter_provider.dart';

/// Horizontal scrolling row of category filter chips.
///
/// Selecting a chip updates the [propertyFilterProvider] which triggers
/// a property list reload.
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  /// Category value sent to the API mapped to its display label.
  /// `null` key represents "All" (no category filter).
  static const List<_CategoryOption> _categories = [
    _CategoryOption(value: null, label: 'All', icon: Icons.grid_view_rounded),
    _CategoryOption(
        value: 'Family', label: 'Family', icon: Icons.family_restroom),
    _CategoryOption(value: 'Bachelor', label: 'Bachelor', icon: Icons.person),
    _CategoryOption(
        value: 'Sublet', label: 'Sublet', icon: Icons.swap_horiz_rounded),
    _CategoryOption(
        value: 'Hostel', label: 'Hostel/Mess', icon: Icons.hotel_rounded),
    _CategoryOption(
        value: 'Office', label: 'Office', icon: Icons.business_rounded),
    _CategoryOption(
        value: 'Shop', label: 'Shop', icon: Icons.storefront_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(
      propertyFilterProvider.select((s) => s.category),
    );

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _categories[index];
          final isSelected = selectedCategory == option.value;

          return FilterChip(
            selected: isSelected,
            avatar: Icon(
              option.icon,
              size: 18,
              color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            ),
            label: Text(option.label),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
            ),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            checkmarkColor: AppColors.onPrimary,
            showCheckmark: false,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onSelected: (_) {
              ref
                  .read(propertyFilterProvider.notifier)
                  .setCategory(option.value);
            },
          );
        },
      ),
    );
  }
}

class _CategoryOption {
  const _CategoryOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String? value;
  final String label;
  final IconData icon;
}
