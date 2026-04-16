import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';

/// Provides the current user's points ledger history.
final pointsHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getPointsHistory();
});

/// Provides the current user's bonus records.
final bonusHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getBonusHistory();
});

/// Provides the current user's withdrawal records.
final withdrawalHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getWithdrawalHistory();
});
