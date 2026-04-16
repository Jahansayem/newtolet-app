import 'package:intl/intl.dart';

/// Formatting utilities used across the NewTolet application.
class Formatters {
  Formatters._();

  // ---------------------------------------------------------------------------
  // Currency / points
  // ---------------------------------------------------------------------------

  static final _bdtFormat = NumberFormat('#,##0', 'en_US');
  static final _usdFormat = NumberFormat('#,##0.00', 'en_US');
  static final _pointsFormat = NumberFormat('#,##0', 'en_US');

  /// Formats [amount] as Bangladeshi Taka with the Taka symbol.
  ///
  /// Example: `formatBDT(1234)` returns `"৳1,234"`.
  static String formatBDT(double amount) {
    return '৳${_bdtFormat.format(amount)}';
  }

  /// Formats [amount] as US Dollars.
  ///
  /// Example: `formatUSD(12.34)` returns `"\$12.34"`.
  static String formatUSD(double amount) {
    return '\$${_usdFormat.format(amount)}';
  }

  /// Formats [points] with thousands separator and a trailing "pts" label.
  ///
  /// Example: `formatPoints(1234)` returns `"1,234 pts"`.
  static String formatPoints(int points) {
    return '${_pointsFormat.format(points)} pts';
  }

  // ---------------------------------------------------------------------------
  // Phone
  // ---------------------------------------------------------------------------

  /// Formats a Bangladeshi phone number for display.
  ///
  /// Accepts raw digits with or without country code prefix.
  /// Example: `formatPhoneNumber("+8801712345678")` returns `"+880 1712-345678"`.
  static String formatPhoneNumber(String phone) {
    // Strip all non-digit characters.
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure country code prefix.
    if (digits.startsWith('880')) {
      // Already has country code.
    } else if (digits.startsWith('0')) {
      digits = '880${digits.substring(1)}';
    } else {
      digits = '880$digits';
    }

    // Expected: 13 digits (880 + 10-digit local).
    if (digits.length >= 13) {
      final cc = digits.substring(0, 3); // 880
      final operator = digits.substring(3, 7); // 4 digits
      final subscriber = digits.substring(7, 13); // 6 digits
      return '+$cc $operator-$subscriber';
    }

    // Fallback -- return cleaned digits with country code prefix.
    return '+$digits';
  }
}
