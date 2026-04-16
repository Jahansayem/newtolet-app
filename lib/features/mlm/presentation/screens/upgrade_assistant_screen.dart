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

class UpgradeAssistantScreen extends ConsumerWidget {
  const UpgradeAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upgradeAsync = ref.watch(upgradeAssistantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Levels & Rewards'),
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
      body: upgradeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(error: error.toString()),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserProvider);
            ref.invalidate(teamStatsProvider);
            ref.invalidate(upgradeAssistantProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _StatusHeader(data: data),
              const SizedBox(height: 24),
              _ListingTargetsSection(data: data),
              const SizedBox(height: 18),
              _ListingStreakBonusCard(data: data),
              const SizedBox(height: 28),
              _LevelsTimeline(data: data),
              const SizedBox(height: 28),
              _InviteCta(onTap: () => context.goNamed(RouteNames.invite)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.data});

  final UpgradeAssistantData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF005A1D), Color(0xFF008E35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status'.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.currentLevelMemberLabel,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Current reward: ${data.currentRewardLabel}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.isMaxLevel
                          ? 'Top tier'
                          : 'Next: ${data.nextLevelLabel}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.overallProgressPercent}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: data.overallProgressToNext,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.nextLevelRequirementSummary,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                icon: Icons.bolt_outlined,
                label: 'PPV ${data.formattedPpv}',
              ),
              _StatusChip(
                icon: Icons.people_alt_outlined,
                label: 'Team ${data.teamSize}',
              ),
              _StatusChip(
                icon: Icons.workspace_premium_outlined,
                label: data.isReferralEligible
                    ? 'Referral active'
                    : 'Referral locked',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingTargetsSection extends StatelessWidget {
  const _ListingTargetsSection({required this.data});

  final UpgradeAssistantData data;

  @override
  Widget build(BuildContext context) {
    final milestones = data.listingTargetMilestones;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                      'Listing Targets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.approvedListings} approved listings so far',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${data.listingTargetProgressPercent}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: data.listingTargetProgressPercent / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.listingTargetProgressLabel,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < milestones.length; index++) ...[
            _ListingTargetRow(milestone: milestones[index]),
            if (index != milestones.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ListingTargetRow extends StatelessWidget {
  const _ListingTargetRow({required this.milestone});

  final ListingTargetProgressData milestone;

  @override
  Widget build(BuildContext context) {
    final badgeColor = switch (milestone.status) {
      ListingTargetStatus.completed => AppColors.success,
      ListingTargetStatus.current => AppColors.primary,
      ListingTargetStatus.locked => AppColors.textHint,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: milestone.isCurrent
            ? AppColors.surfaceVariant
            : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: milestone.isCurrent
              ? AppColors.primary.withValues(alpha: 0.22)
              : AppColors.border.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  milestone.milestone,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: milestone.isCurrent
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  milestone.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Target Listings',
                  value: '${milestone.targetListings}',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  label: 'Reward / Listing',
                  value:
                      '${Formatters.formatPoints(milestone.rewardPerListing).replaceAll(' pts', '')} pts',
                ),
              ),
              Expanded(
                child: _MetricItem(
                  label: 'Total Value',
                  value:
                      '${Formatters.formatPoints(milestone.totalTargetValue).replaceAll(' pts', '')} pts',
                  emphasize: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListingStreakBonusCard extends StatelessWidget {
  const _ListingStreakBonusCard({required this.data});

  final UpgradeAssistantData data;

  @override
  Widget build(BuildContext context) {
    final accentColor = data.streakQualified
        ? AppColors.success
        : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.streakQualified
              ? [const Color(0xFF0E6E3A), const Color(0xFF18A75B)]
              : [const Color(0xFF8E5E00), const Color(0xFFDA9A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '30-Day Streak Bonus'.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data.formattedStreakBonusPoints} bonus points',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Maintain minimum ${data.streakRuleLabel} to unlock the reward.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.streakQualified ? 'Unlocked' : 'Current streak',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.currentQualifyingStreakDays}/${data.streakDaysRequired}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: data.streakProgress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.streakSummary,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelsTimeline extends StatelessWidget {
  const _LevelsTimeline({required this.data});

  final UpgradeAssistantData data;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 22,
          top: 12,
          bottom: 12,
          child: Container(width: 2, color: AppColors.border),
        ),
        Column(
          children: [
            for (final level in data.timelineLevels)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TimelineCard(level: level),
              ),
          ],
        ),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.level});

  final RewardLevelCardData level;

  @override
  Widget build(BuildContext context) {
    final statusColor = level.isCurrent
        ? AppColors.primary
        : level.isCompleted
        ? AppColors.textHint
        : AppColors.border;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Container(
                width: level.isCurrent ? 16 : 12,
                height: level.isCurrent ? 16 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: level.isCurrent ? AppColors.primary : statusColor,
                  border: Border.all(
                    color: Colors.white,
                    width: level.isCurrent ? 4 : 2,
                  ),
                  boxShadow: level.isCurrent
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Opacity(
                opacity: level.isCompleted && !level.isCurrent ? 0.72 : 1,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: level.isCurrent
                          ? AppColors.primary.withValues(alpha: 0.22)
                          : AppColors.border.withValues(alpha: 0.6),
                      width: level.isCurrent ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level.title,
                                  style: TextStyle(
                                    fontSize: level.isCurrent ? 21 : 18,
                                    fontWeight: FontWeight.w800,
                                    color: level.isCurrent
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  level.subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBadgeColor(
                                    level.status,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  level.statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: _statusBadgeColor(level.status),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: level.isCurrent
                                      ? AppColors.surfaceVariant
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _rewardIconData(level.rewardIcon),
                                  color: level.isCurrent
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricItem(
                              label: 'Team Size',
                              value: '${level.teamSizeRequired}',
                            ),
                          ),
                          Expanded(
                            child: _MetricItem(
                              label: 'Direct Bonus',
                              value: '${level.directBonusPercent}%',
                            ),
                          ),
                          Expanded(
                            child: _MetricItem(
                              label: 'Reward',
                              value: level.rewardLabel,
                              emphasize: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        level.indirectBonusPercent > 0
                            ? 'Indirect bonus ${level.indirectBonusPercent}% / ${level.ppvRequired} PPV target'
                            : '${level.ppvRequired} PPV target',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusBadgeColor(RewardLevelStatus status) {
    switch (status) {
      case RewardLevelStatus.completed:
        return AppColors.textSecondary;
      case RewardLevelStatus.current:
        return AppColors.primary;
      case RewardLevelStatus.locked:
        return AppColors.textHint;
    }
  }

  IconData _rewardIconData(String rewardIcon) {
    switch (rewardIcon) {
      case 'minus':
        return Icons.remove_rounded;
      case 'percent':
        return Icons.percent_rounded;
      case 'seed':
        return Icons.spa_outlined;
      case 'star':
        return Icons.star_rounded;
      case 'phone':
        return Icons.smartphone_outlined;
      case 'phone_classic':
        return Icons.phone_android_outlined;
      case 'laptop':
        return Icons.laptop_chromebook_outlined;
      case 'medal':
        return Icons.workspace_premium_outlined;
      case 'motorcycle':
        return Icons.two_wheeler_outlined;
      case 'briefcase':
        return Icons.work_outline;
      case 'flight':
        return Icons.flight_takeoff_outlined;
      case 'trophy':
        return Icons.emoji_events_outlined;
      case 'car':
        return Icons.directions_car_filled_outlined;
      default:
        return Icons.card_giftcard_outlined;
    }
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 0.4,
            color: AppColors.textHint,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: emphasize ? 13 : 14,
            fontWeight: FontWeight.w800,
            color: emphasize ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InviteCta extends StatelessWidget {
  const _InviteCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scale Your Earnings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Invite more partners to climb the ladder faster and unlock the next reward tier.',
            style: TextStyle(fontSize: 14, height: 1.4, color: Colors.white),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text(
                'Invite Partners Now',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Could not load levels and rewards',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
