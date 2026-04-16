import '../../../core/constants/app_constants.dart';

class WithdrawalPolicy {
  WithdrawalPolicy._();

  static const Duration _dhakaOffset = Duration(hours: 6);
  static const Set<String> _nonBlockingStatuses = {
    'rejected',
    'failed',
    'cancelled',
  };

  static DateTime toDhaka(DateTime dateTime) =>
      dateTime.toUtc().add(_dhakaOffset);

  static bool isWindowOpen(DateTime dateTime) {
    final dhakaDate = toDhaka(dateTime);
    return dhakaDate.day >= AppConstants.withdrawalWindowStartDay &&
        dhakaDate.day <= AppConstants.withdrawalWindowEndDay;
  }

  static bool hasMonthlyRequest(
    Iterable<Map<String, dynamic>> withdrawals,
    DateTime dateTime,
  ) {
    final current = toDhaka(dateTime);
    for (final withdrawal in withdrawals) {
      final createdAt = _parseCreatedAt(withdrawal);
      if (createdAt == null) {
        continue;
      }

      final entry = toDhaka(createdAt);
      if (entry.year == current.year && entry.month == current.month) {
        return true;
      }
    }
    return false;
  }

  static double reservedUsd(Iterable<Map<String, dynamic>> withdrawals) {
    double total = 0;
    for (final withdrawal in withdrawals) {
      final status = (withdrawal['status'] as String? ?? 'pending')
          .trim()
          .toLowerCase();
      if (_nonBlockingStatuses.contains(status)) {
        continue;
      }
      total += (withdrawal['amount_usd'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  static int requestablePoints({
    required double balanceUsd,
    required Iterable<Map<String, dynamic>> withdrawals,
  }) {
    final availableUsd = (balanceUsd - reservedUsd(withdrawals)).clamp(
      0.0,
      double.infinity,
    );
    return AppConstants.usdToPoints(availableUsd);
  }

  static double pointsToUsd(int points) =>
      AppConstants.pointsToUsdAmount(points);

  static String monthLabel(DateTime dateTime) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final dhakaDate = toDhaka(dateTime);
    return '${monthNames[dhakaDate.month - 1]} ${dhakaDate.year}';
  }

  static DateTime? _parseCreatedAt(Map<String, dynamic> withdrawal) {
    final raw = withdrawal['created_at'];
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
