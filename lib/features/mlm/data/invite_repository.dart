import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../models/invite_model.dart';

/// Provides an [InviteRepository] instance via Riverpod.
final inviteRepositoryProvider = Provider<InviteRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return InviteRepository(client);
});

/// Repository for invite operations backed by the `invites` Supabase table.
class InviteRepository {
  const InviteRepository(this._client);

  final SupabaseClient _client;

  /// Fetches all invites created by the current authenticated user, ordered
  /// by `created_at` descending.
  Future<List<InviteModel>> getMyInvites() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('invites')
        .select()
        .eq('inviter_id', userId)
        .order('created_at', ascending: false);

    final rows = response as List<dynamic>;
    return rows
        .map((row) => InviteModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new invite record for [email] on behalf of the current user.
  ///
  /// Returns the newly created [InviteModel].
  Future<InviteModel> createInvite(String email) async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('invites')
        .insert({
          'inviter_id': userId,
          'invited_email': email.trim().toLowerCase(),
          'status': 'pending',
          'points_awarded': 0,
        })
        .select()
        .single();

    return InviteModel.fromJson(response);
  }

  /// Computes aggregate statistics from the current user's invites.
  Future<InviteStats> getInviteStats() async {
    final invites = await getMyInvites();

    int registered = 0;
    int completed = 0;

    for (final invite in invites) {
      if (invite.status == 'registered') registered++;
      if (invite.status == 'completed') completed++;
    }

    return InviteStats(
      totalInvites: invites.length,
      registeredCount: registered,
      completedCount: completed,
    );
  }
}
