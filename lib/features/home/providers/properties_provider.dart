import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/property_repository.dart';
import '../models/property_model.dart';
import 'property_filter_provider.dart';

// ---------------------------------------------------------------------------
// Properties list state
// ---------------------------------------------------------------------------

class PropertiesState {
  const PropertiesState({
    this.properties = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.favoriteIds = const {},
  });

  final List<PropertyModel> properties;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final Set<String> favoriteIds;

  PropertiesState copyWith({
    List<PropertyModel>? properties,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    Set<String>? favoriteIds,
    bool clearError = false,
  }) {
    return PropertiesState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class PropertiesNotifier extends StateNotifier<PropertiesState> {
  PropertiesNotifier(this._repository, this._ref)
    : super(const PropertiesState()) {
    // Listen to filter changes and reload.
    _ref.listen<PropertyFilterState>(propertyFilterProvider, (previous, next) {
      if (previous != next) {
        loadProperties();
      }
    });
  }

  final PropertyRepository _repository;
  final Ref _ref;

  static const int _pageSize = 20;

  /// Initial load (or reload after filter change).
  Future<void> loadProperties() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final filters = _ref.read(propertyFilterProvider);
      final favoriteIds = await _repository.getFavoriteIds();

      final results = await _repository.getProperties(
        page: 0,
        limit: _pageSize,
        category: filters.category,
        district: filters.district,
        upazila: filters.upazila,
        minRent: filters.minRent,
        maxRent: filters.maxRent,
        search: filters.searchQuery,
        sortBy: filters.sortBy.queryValue,
      );

      final enriched = results
          .map((p) => p.copyWith(isFavorited: favoriteIds.contains(p.id)))
          .toList();

      state = state.copyWith(
        properties: enriched,
        isLoading: false,
        hasMore: results.length >= _pageSize,
        currentPage: 0,
        favoriteIds: favoriteIds,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Loads the next page (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final filters = _ref.read(propertyFilterProvider);
      final nextPage = state.currentPage + 1;

      final results = await _repository.getProperties(
        page: nextPage,
        limit: _pageSize,
        category: filters.category,
        district: filters.district,
        upazila: filters.upazila,
        minRent: filters.minRent,
        maxRent: filters.maxRent,
        search: filters.searchQuery,
        sortBy: filters.sortBy.queryValue,
      );

      final enriched = results
          .map((p) => p.copyWith(isFavorited: state.favoriteIds.contains(p.id)))
          .toList();

      state = state.copyWith(
        properties: [...state.properties, ...enriched],
        isLoadingMore: false,
        hasMore: results.length >= _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Clears state and reloads from page 0.
  Future<void> refresh() async {
    state = const PropertiesState();
    await loadProperties();
  }

  /// Toggles the favorite status for a single property in the list.
  Future<void> toggleFavorite(String propertyId) async {
    final index = state.properties.indexWhere((p) => p.id == propertyId);
    if (index == -1) return;

    final property = state.properties[index];
    final wasFavorited = property.isFavorited;

    // Optimistic update.
    final updatedList = List<PropertyModel>.from(state.properties);
    updatedList[index] = property.copyWith(isFavorited: !wasFavorited);

    final updatedFavIds = Set<String>.from(state.favoriteIds);
    if (wasFavorited) {
      updatedFavIds.remove(propertyId);
    } else {
      updatedFavIds.add(propertyId);
    }

    state = state.copyWith(properties: updatedList, favoriteIds: updatedFavIds);

    try {
      await _repository.toggleFavorite(propertyId, wasFavorited);
    } catch (_) {
      // Revert on failure.
      final revertList = List<PropertyModel>.from(state.properties);
      final revertIndex = revertList.indexWhere((p) => p.id == propertyId);
      if (revertIndex != -1) {
        revertList[revertIndex] = revertList[revertIndex].copyWith(
          isFavorited: wasFavorited,
        );
      }

      final revertFavIds = Set<String>.from(state.favoriteIds);
      if (wasFavorited) {
        revertFavIds.add(propertyId);
      } else {
        revertFavIds.remove(propertyId);
      }

      state = state.copyWith(properties: revertList, favoriteIds: revertFavIds);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, PropertiesState>((ref) {
      final repository = ref.watch(propertyRepositoryProvider);
      final notifier = PropertiesNotifier(repository, ref);
      // Trigger initial load.
      notifier.loadProperties();
      return notifier;
    });

// ---------------------------------------------------------------------------
// Single property detail provider
// ---------------------------------------------------------------------------

/// Fetches a single property by ID. Used by the detail screen.
final propertyDetailProvider = FutureProvider.family<PropertyModel, String>((
  ref,
  id,
) async {
  final repository = ref.watch(propertyRepositoryProvider);
  final favoriteIds = await repository.getFavoriteIds();
  final property = await repository.getPropertyById(id);
  return property.copyWith(isFavorited: favoriteIds.contains(property.id));
});
