import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/current_user_provider.dart';
import '../data/team_repository.dart';
import '../data/upgrade_assistant_repository.dart';
import '../models/upgrade_assistant_model.dart';

final upgradeAssistantProvider = FutureProvider<UpgradeAssistantData>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final repository = ref.read(upgradeAssistantRepositoryProvider);
  final teamRepository = ref.read(teamRepositoryProvider);

  final approvedListingsFuture = repository.getApprovedListingCount(user.id);
  final dailyListingCountsFuture = repository.getApprovedListingDailyCounts(
    user.id,
  );
  final teamSizeFuture = teamRepository.getTeamSize(user.id);
  final roleFuture = repository.getActiveRole(user.role);

  final approvedListings = await approvedListingsFuture;
  final dailyListingCounts = await dailyListingCountsFuture;
  final teamSize = await teamSizeFuture;
  final roleConfig = await roleFuture;

  return UpgradeAssistantData.fromInputs(
    user: user,
    teamSize: teamSize,
    approvedListings: approvedListings,
    dailyListingCounts: dailyListingCounts,
    roleConfig: roleConfig,
  );
});
