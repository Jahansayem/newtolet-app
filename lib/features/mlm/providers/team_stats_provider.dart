import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/current_user_provider.dart';
import '../data/team_repository.dart';
import '../models/team_stats.dart';

/// Provides aggregated team statistics for the current user's entire downline.
///
/// Automatically invalidates when the current user changes.
final teamStatsProvider = FutureProvider<TeamStats>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    return const TeamStats(
      totalSize: 0,
      activeCount: 0,
      commonCount: 0,
      lowActiveCount: 0,
      gpvThisMonth: 0,
      newJoinsThisMonth: 0,
    );
  }

  final repo = ref.read(teamRepositoryProvider);
  return repo.getTeamStats(user.id);
});
