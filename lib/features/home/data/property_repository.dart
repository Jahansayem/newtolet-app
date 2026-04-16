import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../models/property_model.dart';

/// Provides the [PropertyRepository] singleton through Riverpod.
final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PropertyRepository(client);
});

/// Repository for property CRUD operations against Supabase.
///
/// All read queries use the joined select pattern:
/// ```sql
/// select('*, property_images(*), property_amenities(*)')
/// ```
class PropertyRepository {
  PropertyRepository(this._client);

  final SupabaseClient _client;

  static const String _selectAll =
      '*, property_images(*), property_amenities(*)';

  // ---------------------------------------------------------------------------
  // Read operations
  // ---------------------------------------------------------------------------

  /// Fetches a paginated list of approved properties with optional filters.
  ///
  /// [page] is zero-based. Each page returns up to [limit] rows.
  /// Optional filters narrow the result set:
  /// - [category] filters on the `category` column (exact match).
  /// - [district] filters on the legacy `area` column (exact match).
  /// - [upazila] filters on the legacy `sub_area` column (exact match).
  /// - [minRent] / [maxRent] filter on `rent_amount_bdt`.
  /// - [search] does a case-insensitive pattern search across
  ///   `short_description`, `area`, and `state_district`.
  Future<List<PropertyModel>> getProperties({
    int page = 0,
    int limit = 20,
    String? category,
    String? district,
    String? upazila,
    int? minRent,
    int? maxRent,
    String? search,
    String sortBy = 'newest',
  }) async {
    final from = page * limit;
    final to = from + limit - 1;

    // Build the filter chain. All filter methods return the same
    // PostgrestFilterBuilder type, so they can be chained with reassignment.
    var query = _client
        .from('properties')
        .select(_selectAll)
        .eq('status', 'approved');

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    if (district != null && district.isNotEmpty) {
      query = query.eq('area', district);
    }

    if (upazila != null && upazila.isNotEmpty) {
      query = query.eq('sub_area', upazila);
    }

    if (minRent != null) {
      query = query.gte('rent_amount_bdt', minRent);
    }

    if (maxRent != null) {
      query = query.lte('rent_amount_bdt', maxRent);
    }

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'short_description.ilike.%$search%,'
        'area.ilike.%$search%,'
        'state_district.ilike.%$search%,'
        'sub_area.ilike.%$search%',
      );
    }

    // Sorting and pagination produce a PostgrestTransformBuilder, so they
    // must be applied in a single terminal chain without reassignment.
    final String orderColumn;
    final bool ascending;
    switch (sortBy) {
      case 'priceAsc':
        orderColumn = 'rent_amount_bdt';
        ascending = true;
      case 'priceDesc':
        orderColumn = 'rent_amount_bdt';
        ascending = false;
      default:
        orderColumn = 'created_at';
        ascending = false;
    }

    final response = await query
        .order(orderColumn, ascending: ascending)
        .range(from, to);

    return (response as List<dynamic>)
        .map((row) => PropertyModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single property by its UUID, including images and amenities.
  Future<PropertyModel> getPropertyById(String id) async {
    final response = await _client
        .from('properties')
        .select(_selectAll)
        .eq('id', id)
        .single();

    return PropertyModel.fromJson(response);
  }

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------

  /// Toggles the favorite state for a property.
  ///
  /// When [isFavorited] is `true`, the row already exists and should be
  /// removed. When `false`, a new row is inserted.
  Future<void> toggleFavorite(String propertyId, bool isFavorited) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (isFavorited) {
      // Currently favorited -- remove it.
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('property_id', propertyId);
    } else {
      // Not favorited -- add it.
      await _client.from('favorites').upsert({
        'user_id': userId,
        'property_id': propertyId,
      });
    }
  }

  /// Returns the set of property IDs the current user has favorited.
  Future<Set<String>> getFavoriteIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _client
        .from('favorites')
        .select('property_id')
        .eq('user_id', userId);

    return (response as List<dynamic>)
        .map((row) => (row as Map<String, dynamic>)['property_id'] as String)
        .toSet();
  }

  // ---------------------------------------------------------------------------
  // View tracking
  // ---------------------------------------------------------------------------

  /// Increments the `views` count for the given property.
  Future<void> incrementViews(String propertyId) async {
    // Use an RPC call if available, otherwise fall back to a read-then-update.
    // This approach avoids race conditions by using Supabase's SQL function
    // pattern. If an RPC `increment_property_views` does not exist, we
    // perform a manual increment.
    try {
      await _client.rpc(
        'increment_property_views',
        params: {'p_id': propertyId},
      );
    } on PostgrestException {
      // RPC not available -- fall back to manual increment.
      final current = await _client
          .from('properties')
          .select('views')
          .eq('id', propertyId)
          .single();
      final currentViews = (current['views'] as num?)?.toInt() ?? 0;
      await _client
          .from('properties')
          .update({'views': currentViews + 1})
          .eq('id', propertyId);
    }
  }
}
