import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/current_user_provider.dart';
import '../data/team_repository.dart';
import '../models/team_member.dart';

/// Manages the expandable team tree. The root state contains direct referrals
/// of the current user. Deeper levels are lazy-loaded via [loadChildren].
final teamTreeProvider =
    AsyncNotifierProvider<TeamTreeNotifier, List<TeamMember>>(
  TeamTreeNotifier.new,
);

class TeamTreeNotifier extends AsyncNotifier<List<TeamMember>> {
  /// Cache of already-loaded children keyed by parent user ID.
  final Map<String, List<TeamMember>> _childrenCache = {};

  @override
  Future<List<TeamMember>> build() async {
    return _loadDirectReferrals();
  }

  /// Fetches the direct referrals for the currently authenticated user.
  Future<List<TeamMember>> _loadDirectReferrals() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return [];

    final repo = ref.read(teamRepositoryProvider);
    final members = await repo.getDirectReferrals(user.id);
    return members;
  }

  /// Triggers a full reload of the root-level direct referrals.
  Future<void> refresh() async {
    _childrenCache.clear();
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadDirectReferrals);
  }

  /// Lazy-loads the direct referrals of [parentId] and caches the result.
  ///
  /// Returns the list of children so the UI can render them immediately.
  Future<List<TeamMember>> loadChildren(String parentId) async {
    // Return cached children if already fetched.
    if (_childrenCache.containsKey(parentId)) {
      return _childrenCache[parentId]!;
    }

    final repo = ref.read(teamRepositoryProvider);
    final children = await repo.getDirectReferrals(parentId);
    _childrenCache[parentId] = children;
    return children;
  }

  /// Returns the cached children for [parentId], or null if not yet loaded.
  List<TeamMember>? getCachedChildren(String parentId) {
    return _childrenCache[parentId];
  }

  /// Whether children for [parentId] have been fetched and cached.
  bool hasLoadedChildren(String parentId) {
    return _childrenCache.containsKey(parentId);
  }
}
