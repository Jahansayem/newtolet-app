import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/home/models/property_model.dart';
import '../../../shared/providers/current_user_provider.dart';
import '../data/listing_repository.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final myListingsProvider =
    AsyncNotifierProvider.autoDispose<MyListingsNotifier, List<PropertyModel>>(
  MyListingsNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class MyListingsNotifier extends AutoDisposeAsyncNotifier<List<PropertyModel>> {
  @override
  Future<List<PropertyModel>> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) return [];

    final repo = ref.read(listingRepositoryProvider);
    return repo.getMyListings(user.id);
  }

  /// Force a refresh after creating or deleting a listing.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  /// Deletes a listing and refreshes the list.
  Future<void> deleteListing(String propertyId) async {
    final repo = ref.read(listingRepositoryProvider);
    await repo.deleteListing(propertyId);
    await refresh();
  }
}
