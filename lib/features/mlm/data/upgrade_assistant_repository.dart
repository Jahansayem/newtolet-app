import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/listing_role_model.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../models/upgrade_assistant_model.dart';

final upgradeAssistantRepositoryProvider = Provider<UpgradeAssistantRepository>(
  (ref) {
    return UpgradeAssistantRepository(ref.watch(supabaseClientProvider));
  },
);

class UpgradeAssistantRepository {
  const UpgradeAssistantRepository(this._client);

  final SupabaseClient _client;

  Future<int> getApprovedListingCount(String userId) async {
    final response = await _client
        .from('properties')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'approved');

    return (response as List<dynamic>).length;
  }

  Future<List<ListingDailyCount>> getApprovedListingDailyCounts(
    String userId, {
    int days = AppConstants.listingStreakDaysRequired,
  }) async {
    final safeDays = days.clamp(1, 60).toInt();

    try {
      final response = await _client.rpc(
        'get_approved_listing_daily_counts',
        params: {'p_user_id': userId, 'p_days': safeDays},
      );

      final rows = List<Map<String, dynamic>>.from(response as List<dynamic>);
      return rows
          .map(
            (row) => ListingDailyCount(
              day: DateTime.parse('${row['activity_date']}T00:00:00Z'),
              count: (row['listing_count'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList()
        ..sort((a, b) => a.day.compareTo(b.day));
    } catch (_) {
      final now = DateTime.now().toUtc();
      final cutoffDay = _dhakaDay(now.subtract(Duration(days: safeDays - 1)));
      final fallbackStart = now.subtract(Duration(days: safeDays + 7));

      final response = await _client
          .from('properties')
          .select('created_at, listing_points_awarded_at')
          .eq('user_id', userId)
          .eq('status', 'approved')
          .gte('created_at', fallbackStart.toIso8601String());

      final countsByDay = <DateTime, int>{};
      for (final entry in List<Map<String, dynamic>>.from(response)) {
        final rawTimestamp =
            entry['listing_points_awarded_at'] ?? entry['created_at'];
        if (rawTimestamp is! String) {
          continue;
        }

        final day = _dhakaDay(DateTime.parse(rawTimestamp));
        if (day.isBefore(cutoffDay)) {
          continue;
        }

        countsByDay.update(day, (value) => value + 1, ifAbsent: () => 1);
      }

      return countsByDay.entries
          .map((entry) => ListingDailyCount(day: entry.key, count: entry.value))
          .toList()
        ..sort((a, b) => a.day.compareTo(b.day));
    }
  }

  Future<ListingRoleModel?> getActiveRole(String roleKey) async {
    try {
      final response = await _client
          .from('listing_roles')
          .select()
          .eq('role_key', roleKey.trim().toLowerCase())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return ListingRoleModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  DateTime _dhakaDay(DateTime timestamp) {
    final shifted = timestamp.toUtc().add(AppConstants.dhakaUtcOffset);
    return DateTime.utc(shifted.year, shifted.month, shifted.day);
  }
}
