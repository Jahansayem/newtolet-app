import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Sort options
// ---------------------------------------------------------------------------

enum PropertySortBy { newest, priceAsc, priceDesc }

extension PropertySortByX on PropertySortBy {
  String get queryValue {
    switch (this) {
      case PropertySortBy.newest:
        return 'newest';
      case PropertySortBy.priceAsc:
        return 'priceAsc';
      case PropertySortBy.priceDesc:
        return 'priceDesc';
    }
  }

  String get label {
    switch (this) {
      case PropertySortBy.newest:
        return 'Newest First';
      case PropertySortBy.priceAsc:
        return 'Price: Low to High';
      case PropertySortBy.priceDesc:
        return 'Price: High to Low';
    }
  }
}

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

class PropertyFilterState {
  const PropertyFilterState({
    this.category,
    this.district,
    this.upazila,
    this.minRent,
    this.maxRent,
    this.searchQuery,
    this.sortBy = PropertySortBy.newest,
  });

  final String? category;
  final String? district;
  final String? upazila;
  final int? minRent;
  final int? maxRent;
  final String? searchQuery;
  final PropertySortBy sortBy;

  /// Returns `true` when any filter other than sort is active.
  bool get hasActiveFilters =>
      category != null ||
      district != null ||
      upazila != null ||
      minRent != null ||
      maxRent != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  PropertyFilterState copyWith({
    String? category,
    String? district,
    String? upazila,
    int? minRent,
    int? maxRent,
    String? searchQuery,
    PropertySortBy? sortBy,
    bool clearCategory = false,
    bool clearDistrict = false,
    bool clearUpazila = false,
    bool clearMinRent = false,
    bool clearMaxRent = false,
    bool clearSearch = false,
  }) {
    return PropertyFilterState(
      category: clearCategory ? null : (category ?? this.category),
      district: clearDistrict ? null : (district ?? this.district),
      upazila: clearUpazila ? null : (upazila ?? this.upazila),
      minRent: clearMinRent ? null : (minRent ?? this.minRent),
      maxRent: clearMaxRent ? null : (maxRent ?? this.maxRent),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyFilterState &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          district == other.district &&
          upazila == other.upazila &&
          minRent == other.minRent &&
          maxRent == other.maxRent &&
          searchQuery == other.searchQuery &&
          sortBy == other.sortBy;

  @override
  int get hashCode => Object.hash(
    category,
    district,
    upazila,
    minRent,
    maxRent,
    searchQuery,
    sortBy,
  );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class PropertyFilterNotifier extends StateNotifier<PropertyFilterState> {
  PropertyFilterNotifier() : super(const PropertyFilterState());

  void setCategory(String? category) {
    if (category == state.category) return;
    state = state.copyWith(category: category, clearCategory: category == null);
  }

  void setDistrict(String? district) {
    state = state.copyWith(
      district: district,
      clearUpazila: true,
      clearDistrict: district == null,
    );
  }

  void setUpazila(String? upazila) {
    state = state.copyWith(upazila: upazila, clearUpazila: upazila == null);
  }

  void setPriceRange({int? min, int? max}) {
    state = state.copyWith(
      minRent: min,
      maxRent: max,
      clearMinRent: min == null,
      clearMaxRent: max == null,
    );
  }

  void setSearch(String? query) {
    final trimmed = query?.trim();
    if (trimmed == state.searchQuery) return;
    state = state.copyWith(
      searchQuery: trimmed,
      clearSearch: trimmed == null || trimmed.isEmpty,
    );
  }

  void setSortBy(PropertySortBy sortBy) {
    if (sortBy == state.sortBy) return;
    state = state.copyWith(sortBy: sortBy);
  }

  void clearAll() {
    state = const PropertyFilterState();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final propertyFilterProvider =
    StateNotifierProvider<PropertyFilterNotifier, PropertyFilterState>((ref) {
      return PropertyFilterNotifier();
    });
