import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/invite_repository.dart';
import '../models/invite_model.dart';

/// Manages the list of invites created by the current user.
final inviteListProvider =
    AsyncNotifierProvider<InviteListNotifier, List<InviteModel>>(
  InviteListNotifier.new,
);

class InviteListNotifier extends AsyncNotifier<List<InviteModel>> {
  @override
  Future<List<InviteModel>> build() async {
    final repo = ref.read(inviteRepositoryProvider);
    return repo.getMyInvites();
  }

  /// Sends a new invite to [email] and prepends it to the current state.
  Future<void> createInvite(String email) async {
    final repo = ref.read(inviteRepositoryProvider);
    final newInvite = await repo.createInvite(email);

    final current = state.valueOrNull ?? [];
    state = AsyncData([newInvite, ...current]);
  }

  /// Triggers a full reload of the invite list from Supabase.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(inviteRepositoryProvider);
    state = await AsyncValue.guard(repo.getMyInvites);
  }
}

/// Provides aggregated invite statistics for the current user.
final inviteStatsProvider = FutureProvider<InviteStats>((ref) async {
  final repo = ref.read(inviteRepositoryProvider);
  return repo.getInviteStats();
});
