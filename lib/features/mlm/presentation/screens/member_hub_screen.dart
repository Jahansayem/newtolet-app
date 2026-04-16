import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/current_user_provider.dart';
import '../../models/upgrade_assistant_model.dart';
import '../../providers/team_stats_provider.dart';
import '../../providers/upgrade_assistant_provider.dart';
import '../widgets/activity_status_dot.dart';
import '../widgets/star_level_badge.dart';

/// Tab 3 of the bottom navigation bar. Displays the current user's MLM
/// dashboard with star level, PPV, quick stats, and navigation cards to
/// team tree, invites, earnings, and other tools.
class MemberHubScreen extends ConsumerWidget {
  const MemberHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(teamStatsProvider);
    final upgradeAsync = ref.watch(upgradeAssistantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(currentUserProvider);
              ref.invalidate(teamStatsProvider);
              ref.invalidate(upgradeAssistantProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load profile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please sign in to continue.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserProvider);
              ref.invalidate(teamStatsProvider);
              ref.invalidate(upgradeAssistantProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // -------------------------------------------------------
                // Star level header
                // -------------------------------------------------------
                _ProfileHeader(
                  name: user.name ?? 'Agent',
                  starLevel: user.starLevel,
                  ppv: user.ppv,
                  activityStatus: user.activityStatus,
                ),

                const SizedBox(height: 20),

                // -------------------------------------------------------
                // Quick stats row
                // -------------------------------------------------------
                statsAsync.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (stats) => _QuickStatsRow(
                    teamSize: stats.totalSize,
                    activePercent: stats.activePercentFormatted,
                    gpv: stats.gpvThisMonth,
                    balanceUsd: user.balanceUsd,
                  ),
                ),

                const SizedBox(height: 16),

                upgradeAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (data) => _UpgradeSnapshotCard(data: data),
                ),

                const SizedBox(height: 24),

                // -------------------------------------------------------
                // Quick tools heading
                // -------------------------------------------------------
                Text(
                  'Quick Tools',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),

                // -------------------------------------------------------
                // Quick tools grid (2 columns x 3 rows)
                // -------------------------------------------------------
                _QuickToolsGrid(activityStatus: user.activityStatus),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile header with star badge and PPV
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.starLevel,
    required this.ppv,
    required this.activityStatus,
  });

  final String name;
  final int starLevel;
  final int ppv;
  final String activityStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              StarLevelBadge(starLevel: starLevel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // PPV badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'PPV: $ppv',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Activity status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ActivityStatusDot(
                  status: activityStatus,
                  showLabel: true,
                  size: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick stats row
// ---------------------------------------------------------------------------

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.teamSize,
    required this.activePercent,
    required this.gpv,
    required this.balanceUsd,
  });

  final int teamSize;
  final String activePercent;
  final int gpv;
  final double balanceUsd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.people,
          label: 'Team Size',
          value: '$teamSize',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.trending_up,
          label: 'Active',
          value: activePercent,
          color: AppColors.statusActive,
        ),
        _StatCard(
          icon: Icons.bar_chart,
          label: 'GPV',
          value: Formatters.formatPoints(gpv).replaceAll(' pts', ''),
          color: AppColors.secondary,
        ),
        _StatCard(
          icon: Icons.account_balance_wallet,
          label: 'Balance',
          value: Formatters.formatUSD(balanceUsd),
          color: AppColors.warning,
        ),
      ].map((card) => Expanded(child: card)).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeSnapshotCard extends StatelessWidget {
  const _UpgradeSnapshotCard({required this.data});

  final UpgradeAssistantData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Levels & Rewards',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.isMaxLevel
                            ? '${data.currentLevelLabel} complete'
                            : '${data.currentLevelLabel} -> ${data.nextLevelLabel}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.goNamed(RouteNames.upgradeAssistant),
                  child: const Text('Open'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: data.overallProgressToNext,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.isMaxLevel
                  ? 'You already unlocked the highest star.'
                  : '${data.remainingPpvForNext} PPV and ${data.remainingTeamSizeForNext} team members left.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniBadge(
                    icon: Icons.badge_outlined,
                    label: data.roleLabel,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniBadge(
                    icon: Icons.person_add_alt_1_outlined,
                    label: data.isReferralEligible
                        ? 'Referral active'
                        : '${data.approvedListings}/${data.referralUnlockListings} listings',
                    color: data.isReferralEligible
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick tools grid
// ---------------------------------------------------------------------------

class _QuickToolsGrid extends StatelessWidget {
  const _QuickToolsGrid({required this.activityStatus});

  final String activityStatus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _ToolCard(
                icon: Icons.account_tree,
                label: 'My Team',
                color: AppColors.primary,
                onTap: () => context.goNamed(RouteNames.teamTree),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ToolCard(
                icon: Icons.person_add,
                label: 'Invite',
                color: AppColors.secondary,
                onTap: () => context.goNamed(RouteNames.invite),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ToolCard(
                icon: Icons.monetization_on,
                label: 'Earnings',
                color: AppColors.warning,
                onTap: () => context.goNamed(RouteNames.earnings),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ToolCard(
                icon: Icons.upgrade,
                label: 'Levels & Rewards',
                color: AppColors.primaryDark,
                onTap: () => context.goNamed(RouteNames.upgradeAssistant),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _ActiveStatusTool(activityStatus: activityStatus),
            ),
          ],
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveStatusTool extends StatelessWidget {
  const _ActiveStatusTool({required this.activityStatus});

  final String activityStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActivityStatusDot(status: activityStatus, size: 24),
            const SizedBox(height: 8),
            const Text(
              'Active Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            ActivityStatusDot(status: activityStatus, showLabel: true, size: 8),
          ],
        ),
      ),
    );
  }
}
