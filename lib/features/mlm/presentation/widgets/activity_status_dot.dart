import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A small coloured dot that indicates a user's activity status.
///
/// - green = active
/// - blue = common
/// - red = low_active
///
/// Optionally displays a text label beside the dot.
class ActivityStatusDot extends StatelessWidget {
  const ActivityStatusDot({
    required this.status,
    this.showLabel = false,
    this.size = 12.0,
    super.key,
  });

  /// The activity status string: `'active'`, `'common'`, or `'low_active'`.
  final String status;

  /// Whether to display the label text next to the dot.
  final bool showLabel;

  /// Diameter of the dot in logical pixels.
  final double size;

  Color get _color {
    switch (status) {
      case 'active':
        return AppColors.statusActive;
      case 'common':
        return AppColors.statusCommon;
      case 'low_active':
      default:
        return AppColors.statusLowActive;
    }
  }

  String get _label {
    switch (status) {
      case 'active':
        return 'Active';
      case 'common':
        return 'Common';
      case 'low_active':
      default:
        return 'Low Active';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );

    if (!showLabel) return dot;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 6),
        Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _color,
          ),
        ),
      ],
    );
  }
}
