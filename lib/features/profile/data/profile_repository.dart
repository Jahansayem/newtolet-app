import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';

/// Repository handling all profile-related Supabase operations including
/// user profile updates, points/bonus/withdrawal history, and exchange rates.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Updates the current user's profile fields in the `users` table.
  ///
  /// Only non-null parameters are sent to Supabase.
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? bkashNumber,
    String? nagadNumber,
    String? division,
    String? district,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (bkashNumber != null) updates['bkash_number'] = bkashNumber;
    if (nagadNumber != null) updates['nagad_number'] = nagadNumber;
    if (division != null) updates['division'] = division;
    if (district != null) updates['district'] = district;
    updates['updated_at'] = DateTime.now().toIso8601String();

    if (updates.length <= 1) return; // Only updated_at, nothing to change.

    await _client.from('users').update(updates).eq('id', userId);
  }

  // ---------------------------------------------------------------------------
  // Points history
  // ---------------------------------------------------------------------------

  /// Fetches paginated points ledger entries for the current user,
  /// ordered by `created_at` descending.
  Future<List<Map<String, dynamic>>> getPointsHistory({
    int page = 0,
    int limit = 20,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final from = page * limit;
    final to = from + limit - 1;

    final response = await _client
        .from('points_ledger')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(response);
  }

  // ---------------------------------------------------------------------------
  // Bonus history
  // ---------------------------------------------------------------------------

  /// Fetches paginated bonus records for the current user.
  Future<List<Map<String, dynamic>>> getBonusHistory({
    int page = 0,
    int limit = 20,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final from = page * limit;
    final to = from + limit - 1;

    final response = await _client
        .from('bonuses')
        .select()
        .eq('user_id', userId)
        .order('period_start', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(response);
  }

  // ---------------------------------------------------------------------------
  // Withdrawal history
  // ---------------------------------------------------------------------------

  /// Fetches all withdrawal records for the current user.
  Future<List<Map<String, dynamic>>> getWithdrawalHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('withdrawals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ---------------------------------------------------------------------------
  // Withdrawal request
  // ---------------------------------------------------------------------------

  /// Creates a new withdrawal request through a validated backend RPC.
  Future<void> requestWithdrawal({
    required int requestedPoints,
    required String method,
    required String accountNumber,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client.rpc(
      'request_withdrawal',
      params: {
        'p_requested_points': requestedPoints,
        'p_method': method,
        'p_account_number': accountNumber,
      },
    );
  }
}
