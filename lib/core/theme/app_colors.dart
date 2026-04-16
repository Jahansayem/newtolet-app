import 'package:flutter/material.dart';

/// NewTolet brand colour palette.
///
/// The primary palette is green-based to reflect trust and growth, aligned with
/// the property-rental and agent-network identity of NewTolet.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Primary palette
  // ---------------------------------------------------------------------------

  static const Color primary = Color(0xFF2E7D32); // Green 800
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);
  static const Color onPrimary = Colors.white;

  // ---------------------------------------------------------------------------
  // Secondary palette
  // ---------------------------------------------------------------------------

  static const Color secondary = Color(0xFF00897B); // Teal 600
  static const Color secondaryLight = Color(0xFF4EBAAA);
  static const Color secondaryDark = Color(0xFF005B4F);
  static const Color onSecondary = Colors.white;

  // ---------------------------------------------------------------------------
  // Activity-status colours
  // ---------------------------------------------------------------------------

  /// Active status indicator.
  static const Color statusActive = Color(0xFF4CAF50);

  /// Common status indicator.
  static const Color statusCommon = Color(0xFF2196F3);

  /// Low-active / inactive status indicator.
  static const Color statusLowActive = Color(0xFFF44336);

  // ---------------------------------------------------------------------------
  // Semantic colours
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // ---------------------------------------------------------------------------
  // Background & surface
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFFF5F7F5);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFE8F5E9);
  static const Color scaffoldBackground = Color(0xFFF5F7F5);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  static const Color textPrimary = Color(0xFF1B1B1F);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnDark = Colors.white;

  // ---------------------------------------------------------------------------
  // Borders & dividers
  // ---------------------------------------------------------------------------

  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // ---------------------------------------------------------------------------
  // Bottom navigation
  // ---------------------------------------------------------------------------

  static const Color navBarBackground = Colors.white;
  static const Color navBarSelected = primary;
  static const Color navBarUnselected = Color(0xFF9E9E9E);

  // ---------------------------------------------------------------------------
  // Star-level badge colours (gradient start -> end per level)
  // ---------------------------------------------------------------------------

  static const List<List<Color>> starGradients = [
    [Color(0xFFBDBDBD), Color(0xFF9E9E9E)], // Star 0 (none)
    [Color(0xFFE8F5E9), Color(0xFFA5D6A7)], // Star 1
    [Color(0xFFC8E6C9), Color(0xFF66BB6A)], // Star 2
    [Color(0xFF81C784), Color(0xFF43A047)], // Star 3
    [Color(0xFF66BB6A), Color(0xFF2E7D32)], // Star 4
    [Color(0xFF4CAF50), Color(0xFF1B5E20)], // Star 5
    [Color(0xFFFFF176), Color(0xFFFDD835)], // Star 6
    [Color(0xFFFFD54F), Color(0xFFF9A825)], // Star 7
    [Color(0xFFFFCA28), Color(0xFFFF8F00)], // Star 8
  ];
}
