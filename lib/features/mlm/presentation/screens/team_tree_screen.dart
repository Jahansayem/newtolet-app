import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/team_member.dart';
import '../../providers/team_stats_provider.dart';
import '../../providers/team_tree_provider.dart';
import '../widgets/star_level_badge.dart';
import '../widgets/tree_node_widget.dart';

/// Full-screen team tree view with summary header, search, filter chips,
/// and an expandable lazy-loaded tree.
class TeamTreeScreen extends ConsumerStatefulWidget {
  const TeamTreeScreen({super.key});

  @override
  ConsumerState<TeamTreeScreen> createState() => _TeamTreeScreenState();
}

class _TeamTreeScreenState extends ConsumerState<TeamTreeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All';

  static const _filterOptions = ['All', 'Active', 'Common', 'Low Active'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(teamTreeProvider);
    final statsAsync = ref.watch(teamStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(teamTreeProvider.notifier).refresh();
              ref.invalidate(teamStatsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // -------------------------------------------------------------------
          // Summary header
          // -------------------------------------------------------------------
          statsAsync.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (stats) => _SummaryHeader(stats: stats),
          ),

          // -------------------------------------------------------------------
          // Search bar
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // -------------------------------------------------------------------
          // Filter chips
          // -------------------------------------------------------------------
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _filterOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = filter == _activeFilter;
                return FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _activeFilter = filter),
                  selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // -------------------------------------------------------------------
          // Tree list
          // -------------------------------------------------------------------
          Expanded(
            child: treeAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('Failed to load team tree',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(teamTreeProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (members) {
                final filtered = _applyFilters(members);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64,
                            color: AppColors.textHint.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          members.isEmpty
                              ? 'No team members yet'
                              : 'No matches found',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (members.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Invite people to grow your team.',
                            style: TextStyle(
                                color: AppColors.textHint, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return TreeNodeWidget(
                      member: filtered[index],
                      depth: 0,
                      onProfileTap: (member) =>
                          _showMiniProfile(context, member),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Applies search and activity filter to the root-level member list.
  List<TeamMember> _applyFilters(List<TeamMember> members) {
    var result = members;

    // Activity filter.
    if (_activeFilter != 'All') {
      final filterStatus = _activeFilter == 'Low Active'
          ? 'low_active'
          : _activeFilter.toLowerCase();
      result = result
          .where((m) => m.activityStatus == filterStatus)
          .toList();
    }

    // Search filter.
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((m) => m.name.toLowerCase().contains(query))
          .toList();
    }

    return result;
  }

  /// Shows a bottom sheet with a mini-profile for the given team member.
  void _showMiniProfile(BuildContext context, TeamMember member) {
    final dateFormat = DateFormat('dd MMM yyyy');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Avatar
              if (member.profileImageUrl != null &&
                  member.profileImageUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 36,
                  backgroundImage:
                      CachedNetworkImageProvider(member.profileImageUrl!),
                  backgroundColor: AppColors.surfaceVariant,
                )
              else
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Name
              Text(
                member.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              // Star badge
              StarLevelBadge(starLevel: member.starLevel),
              const SizedBox(height: 16),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MiniProfileStat(
                    label: 'PPV',
                    value: '${member.ppv}',
                  ),
                  _MiniProfileStat(
                    label: 'Status',
                    value: member.activityLabel,
                    valueColor: member.activityColor,
                  ),
                  _MiniProfileStat(
                    label: 'Joined',
                    value: member.joinedAt != null
                        ? dateFormat.format(member.joinedAt!)
                        : 'N/A',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Summary header
// ---------------------------------------------------------------------------

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.stats});

  final dynamic stats; // TeamStats

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'Total',
            value: '${stats.totalSize}',
            icon: Icons.people,
          ),
          _SummaryItem(
            label: 'Active',
            value: stats.activePercentFormatted,
            icon: Icons.trending_up,
          ),
          _SummaryItem(
            label: 'GPV',
            value: '${stats.gpvThisMonth}',
            icon: Icons.bar_chart,
          ),
          _SummaryItem(
            label: 'New',
            value: '${stats.newJoinsThisMonth}',
            icon: Icons.person_add,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mini profile stat
// ---------------------------------------------------------------------------

class _MiniProfileStat extends StatelessWidget {
  const _MiniProfileStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
