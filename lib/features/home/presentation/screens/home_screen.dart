import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/data/bd_locations.dart';
import '../../../../shared/providers/current_user_provider.dart';
import '../../providers/properties_provider.dart';
import '../../providers/property_filter_provider.dart';
import '../widgets/category_chips.dart';
import '../widgets/property_card.dart';
import '../widgets/property_shimmer.dart';
import '../widgets/search_bar_widget.dart';

/// The main home screen displayed as Tab 0 of the bottom navigation bar.
///
/// Shows a searchable, filterable, infinitely-scrolling grid of approved
/// property listings.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(propertiesProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(propertiesProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertiesProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NewTolet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: const [SearchBarWidget()],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // -- Category chips --
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: CategoryChips(),
              ),
            ),

            // -- Location + Sort filters --
            SliverToBoxAdapter(child: _FilterRow()),

            // -- Content area --
            if (state.isLoading && state.properties.isEmpty)
              // Initial loading shimmer
              const SliverToBoxAdapter(child: PropertyShimmerGrid())
            else if (state.error != null && state.properties.isEmpty)
              // Error state
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorView(message: state.error!, onRetry: _onRefresh),
              )
            else if (state.properties.isEmpty)
              // Empty state
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyView(),
              )
            else ...[
              // Property grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final property = state.properties[index];
                    return PropertyCard(property: property);
                  }, childCount: state.properties.length),
                ),
              ),

              // Loading more indicator
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),

              // End of list indicator
              if (!state.hasMore && state.properties.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No more listings',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        ),
      ),
      // FAB for agents to add a listing
      floatingActionButton: currentUser.whenOrNull(
        data: (user) {
          if (user == null) return null;
          return FloatingActionButton.extended(
            onPressed: () => context.goNamed(RouteNames.addListing),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text('Add Listing'),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location / Sort filter row
// ---------------------------------------------------------------------------

class _FilterRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(propertyFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _DistrictDropdown(
                  selected: filterState.district,
                  onChanged: (value) {
                    ref
                        .read(propertyFilterProvider.notifier)
                        .setDistrict(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UpazilaDropdown(
                  selectedDistrict: filterState.district,
                  selected: filterState.upazila,
                  onChanged: (value) {
                    ref.read(propertyFilterProvider.notifier).setUpazila(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SortDropdown(
                selected: filterState.sortBy,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(propertyFilterProvider.notifier).setSortBy(value);
                  }
                },
              ),
              const Spacer(),
              if (filterState.hasActiveFilters)
                IconButton(
                  icon: const Icon(Icons.filter_alt_off, size: 20),
                  tooltip: 'Clear all filters',
                  color: AppColors.error,
                  onPressed: () {
                    ref.read(propertyFilterProvider.notifier).clearAll();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// District dropdown
// ---------------------------------------------------------------------------

class _DistrictDropdown extends StatelessWidget {
  const _DistrictDropdown({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final allDistricts = BdLocations.getAllDistricts();

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selected,
          isExpanded: true,
          isDense: true,
          hint: const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textHint,
              ),
              SizedBox(width: 4),
              Text(
                'All Districts',
                style: TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
            ],
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Districts', style: TextStyle(fontSize: 13)),
            ),
            ...allDistricts.map(
              (d) => DropdownMenuItem<String?>(
                value: d,
                child: Text(d, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upazila dropdown
// ---------------------------------------------------------------------------

class _UpazilaDropdown extends StatelessWidget {
  const _UpazilaDropdown({
    required this.selectedDistrict,
    required this.selected,
    required this.onChanged,
  });

  final String? selectedDistrict;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final allUpazilas = selectedDistrict == null
        ? const <String>[]
        : BdLocations.getUpazilas(selectedDistrict!);

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selected,
          isExpanded: true,
          isDense: true,
          hint: const Row(
            children: [
              Icon(
                Icons.pin_drop_outlined,
                size: 16,
                color: AppColors.textHint,
              ),
              SizedBox(width: 4),
              Text(
                'All Upazilas',
                style: TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
            ],
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Upazilas', style: TextStyle(fontSize: 13)),
            ),
            ...allUpazilas.map(
              (item) => DropdownMenuItem<String?>(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
          onChanged: allUpazilas.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort dropdown
// ---------------------------------------------------------------------------

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.selected, required this.onChanged});

  final PropertySortBy selected;
  final ValueChanged<PropertySortBy?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PropertySortBy>(
          value: selected,
          isDense: true,
          icon: const Icon(
            Icons.sort,
            size: 16,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          items: PropertySortBy.values
              .map(
                (s) => DropdownMenuItem<PropertySortBy>(
                  value: s,
                  child: Text(s.label, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No properties found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filters or search terms to find more listings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
