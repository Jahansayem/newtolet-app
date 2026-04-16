import 'package:flutter_test/flutter_test.dart';
import 'package:newtolet/core/constants/app_constants.dart';
import 'package:newtolet/features/profile/domain/withdrawal_policy.dart';

void main() {
  group('WithdrawalPolicy.isWindowOpen', () {
    test('uses Bangladesh time for monthly window start', () {
      final utc = DateTime.utc(2026, 3, 31, 18, 30);

      expect(WithdrawalPolicy.isWindowOpen(utc), isTrue);
    });

    test('closes after Bangladesh date five', () {
      final utc = DateTime.utc(2026, 3, 5, 18, 1);

      expect(WithdrawalPolicy.isWindowOpen(utc), isFalse);
    });
  });

  group('WithdrawalPolicy.hasMonthlyRequest', () {
    test('matches the request month in Bangladesh time', () {
      final withdrawals = [
        {'created_at': '2026-02-28T22:30:00Z', 'status': 'pending'},
      ];

      expect(
        WithdrawalPolicy.hasMonthlyRequest(
          withdrawals,
          DateTime.utc(2026, 3, 2, 0, 0),
        ),
        isTrue,
      );
    });

    test('returns false when there is no request in the current month', () {
      final withdrawals = [
        {'created_at': '2026-02-05T09:00:00Z', 'status': 'completed'},
      ];

      expect(
        WithdrawalPolicy.hasMonthlyRequest(
          withdrawals,
          DateTime.utc(2026, 3, 2, 0, 0),
        ),
        isFalse,
      );
    });
  });

  group('WithdrawalPolicy.requestablePoints', () {
    test('subtracts non-rejected withdrawals from available balance', () {
      final withdrawals = [
        {
          'amount_usd': 1.0,
          'status': 'pending',
          'created_at': '2026-03-01T02:00:00Z',
        },
        {
          'amount_usd': 0.5,
          'status': 'rejected',
          'created_at': '2026-03-02T02:00:00Z',
        },
      ];

      expect(
        WithdrawalPolicy.requestablePoints(
          balanceUsd: 3.0,
          withdrawals: withdrawals,
        ),
        7000,
      );
    });

    test('minimum withdrawal usd is derived from points', () {
      expect(
        AppConstants.minWithdrawalUsd,
        closeTo(WithdrawalPolicy.pointsToUsd(5000), 0.000001),
      );
    });
  });
}
