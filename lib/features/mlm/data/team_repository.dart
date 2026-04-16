import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../models/team_member.dart';
import '../models/team_stats.dart';

/// Provides a [TeamRepository] instance via Riverpod.
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return TeamRepository(client);
});

/// Repository for MLM team tree queries. All data comes from Supabase RPC
/// functions and the `team_tree` / `users` tables.
class TeamRepository {
  const TeamRepository(this._client);

  final SupabaseClient _client;

  /// Returns the direct referrals (depth-1 children) of [userId].
  ///
  /// Calls the `get_direct_referrals` PostgreSQL function.
  Future<List<TeamMember>> getDirectReferrals(String userId) async {
    final response = await _client.rpc(
      'get_direct_referrals',
      params: {'p_user_id': userId},
    );

    final rows = response as List<dynamic>;
    return rows
        .map((row) => TeamMember.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Returns the total team size (all downline members) for [userId].
  ///
  /// Calls the `get_team_size` PostgreSQL function.
  Future<int> getTeamSize(String userId) async {
    final response = await _client.rpc(
      'get_team_size',
      params: {'p_user_id': userId},
    );

    return (response as num?)?.toInt() ?? 0;
  }

  /// Returns the Group Point Volume for [userId] in the current month.
  ///
  /// Calls the `get_gpv` PostgreSQL function. The `p_month` parameter expects
  /// a date string in the format `YYYY-MM-01`.
  Future<int> getGPV(String userId) async {
    final now = DateTime.now();
    final monthStart =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

    final response = await _client.rpc(
      'get_gpv',
      params: {
        'p_user_id': userId,
        'p_month': monthStart,
      },
    );

    return (response as num?)?.toInt() ?? 0;
  }

  /// Fetches the full sponsor downline for [userId] and computes aggregate
  /// team statistics.
  Future<TeamStats> getTeamStats(String userId) async {
    final response = await _client.rpc(
      'get_sponsor_downline',
      params: {'p_user_id': userId},
    );

    final rows = response as List<dynamic>;
    final members = rows
        .map((row) => TeamMember.fromJson(row as Map<String, dynamic>))
        .toList();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    int activeCount = 0;
    int commonCount = 0;
    int lowActiveCount = 0;
    int newJoins = 0;

    for (final member in members) {
      switch (member.activityStatus) {
        case 'active':
          activeCount++;
          break;
        case 'common':
          commonCount++;
          break;
        default:
          lowActiveCount++;
      }

      if (member.joinedAt != null && member.joinedAt!.isAfter(monthStart)) {
        newJoins++;
      }
    }

    final gpv = await getGPV(userId);

    return TeamStats(
      totalSize: members.length,
      activeCount: activeCount,
      commonCount: commonCount,
      lowActiveCount: lowActiveCount,
      gpvThisMonth: gpv,
      newJoinsThisMonth: newJoins,
    );
  }
}
