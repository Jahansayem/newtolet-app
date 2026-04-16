import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Displays a star level badge with gradient colouring based on the user's
/// star level (0 through 8).
///
/// Use [compact] for inline display within tree nodes, or the default
/// expanded style for profile headers.
class StarLevelBadge extends StatelessWidget {
  const StarLevelBadge({
    required this.starLevel,
    this.compact = false,
    super.key,
  });

  /// The star level value between 0 and 8.
  final int starLevel;

  /// When true, renders a smaller badge suitable for list items and tree nodes.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final clampedLevel = starLevel.clamp(0, 8);
    final gradientColors = AppColors.starGradients[clampedLevel];

    if (compact) {
      return _CompactBadge(
        starLevel: clampedLevel,
        gradientColors: gradientColors,
      );
    }

    return _ExpandedBadge(
      starLevel: clampedLevel,
      gradientColors: gradientColors,
    );
  }
}

class _CompactBadge extends StatelessWidget {
  const _CompactBadge({
    required this.starLevel,
    required this.gradientColors,
  });

  final int starLevel;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 12,
            color: starLevel >= 6 ? AppColors.textPrimary : Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            '$starLevel',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: starLevel >= 6 ? AppColors.textPrimary : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedBadge extends StatelessWidget {
  const _ExpandedBadge({
    required this.starLevel,
    required this.gradientColors,
  });

  final int starLevel;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 20,
            color: starLevel >= 6 ? AppColors.textPrimary : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'Star $starLevel',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: starLevel >= 6 ? AppColors.textPrimary : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
