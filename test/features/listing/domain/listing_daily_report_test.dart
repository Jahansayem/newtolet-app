import 'package:flutter_test/flutter_test.dart';
import 'package:newtolet/features/home/models/property_model.dart';
import 'package:newtolet/features/listing/domain/listing_daily_report.dart';

void main() {
  group('ListingDailyReport', () {
    test('counts today and yesterday using Bangladesh calendar days', () {
      final report = ListingDailyReport.fromListings([
        _listing('a', '2026-04-14T18:30:00Z'),
        _listing('b', '2026-04-15T16:30:00Z'),
        _listing('c', '2026-04-14T17:59:59Z'),
        _listing('d', '2026-04-13T18:00:00Z'),
      ], now: DateTime.parse('2026-04-15T06:00:00Z'));

      expect(report.todayCount, 2);
      expect(report.yesterdayCount, 2);
    });

    test('ignores listings older than yesterday and null timestamps', () {
      final report = ListingDailyReport.fromListings([
        _listing('a', null),
        _listing('b', '2026-04-12T23:59:59Z'),
        _listing('c', '2026-04-14T20:00:00Z'),
      ], now: DateTime.parse('2026-04-15T04:00:00Z'));

      expect(report.todayCount, 1);
      expect(report.yesterdayCount, 0);
    });

    test('treats UTC timestamps around midnight as the same Dhaka day', () {
      final report = ListingDailyReport.fromListings([
        _listing('a', '2026-04-14T23:50:00Z'),
        _listing('b', '2026-04-15T00:10:00Z'),
      ], now: DateTime.parse('2026-04-15T02:00:00Z'));

      expect(report.todayCount, 2);
      expect(report.yesterdayCount, 0);
    });
  });
}

PropertyModel _listing(String id, String? createdAt) {
  return PropertyModel(
    id: id,
    userId: 'user-1',
    createdAt: createdAt == null ? null : DateTime.parse(createdAt),
  );
}
