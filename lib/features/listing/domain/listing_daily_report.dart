import '../../../core/constants/app_constants.dart';
import '../../home/models/property_model.dart';

class ListingDailyReport {
  const ListingDailyReport({
    required this.todayCount,
    required this.yesterdayCount,
  });

  final int todayCount;
  final int yesterdayCount;

  factory ListingDailyReport.fromListings(
    Iterable<PropertyModel> listings, {
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now();
    final today = _dhakaDay(referenceNow);
    final yesterday = today.subtract(const Duration(days: 1));

    var todayCount = 0;
    var yesterdayCount = 0;

    for (final listing in listings) {
      final createdAt = listing.createdAt;
      if (createdAt == null) {
        continue;
      }

      final listingDay = _dhakaDay(createdAt);
      if (listingDay == today) {
        todayCount++;
      } else if (listingDay == yesterday) {
        yesterdayCount++;
      }
    }

    return ListingDailyReport(
      todayCount: todayCount,
      yesterdayCount: yesterdayCount,
    );
  }

  static DateTime _dhakaDay(DateTime timestamp) {
    final shifted = timestamp.toUtc().add(AppConstants.dhakaUtcOffset);
    return DateTime.utc(shifted.year, shifted.month, shifted.day);
  }
}
