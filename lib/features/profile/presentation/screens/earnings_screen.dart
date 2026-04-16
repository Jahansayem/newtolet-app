import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/profile_provider.dart';

/// Earnings detail screen with three tabs: Points, Bonuses, and Withdrawals.
///
/// Includes a summary card at the top with aggregate totals.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Earnings'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Points'),
              Tab(text: 'Bonuses'),
              Tab(text: 'Withdrawals'),
            ],
          ),
        ),
        body: Column(
          children: [
            _SummaryCard(),
            const Expanded(
              child: TabBarView(
                children: [_PointsTab(), _BonusesTab(), _WithdrawalsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Summary card
// =============================================================================

class _SummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(pointsHistoryProvider);
    final bonusAsync = ref.watch(bonusHistoryProvider);
    final withdrawalAsync = ref.watch(withdrawalHistoryProvider);

    final totalPoints = pointsAsync.maybeWhen(
      data: (entries) {
        int sum = 0;
        for (final e in entries) {
          sum += (e['points'] as num?)?.toInt() ?? 0;
        }
        return sum;
      },
      orElse: () => 0,
    );

    final totalBonusUsd = bonusAsync.maybeWhen(
      data: (entries) {
        double sum = 0;
        for (final e in entries) {
          sum += (e['amount_usd'] as num?)?.toDouble() ?? 0;
        }
        return sum;
      },
      orElse: () => 0.0,
    );

    final pendingWithdrawals = withdrawalAsync.maybeWhen(
      data: (entries) {
        int count = 0;
        for (final e in entries) {
          if (e['status'] == 'pending') count++;
        }
        return count;
      },
      orElse: () => 0,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Total Points',
            value: Formatters.formatPoints(totalPoints),
            icon: Icons.stars_rounded,
            color: AppColors.warning,
          ),
          _verticalDivider(),
          _SummaryItem(
            label: 'Total Bonus',
            value: Formatters.formatUSD(totalBonusUsd),
            icon: Icons.card_giftcard_rounded,
            color: AppColors.success,
          ),
          _verticalDivider(),
          _SummaryItem(
            label: 'Pending',
            value: '$pendingWithdrawals',
            icon: Icons.hourglass_bottom_rounded,
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 40, color: AppColors.border);
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Points tab
// =============================================================================

class _PointsTab extends ConsumerWidget {
  const _PointsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(pointsHistoryProvider);

    return pointsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(pointsHistoryProvider),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const _EmptyView(
            icon: Icons.stars_rounded,
            message: 'No points earned yet',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final action = entry['action'] as String? ?? 'unknown';
            final description = entry['description'] as String? ?? '';
            final points = (entry['points'] as num?)?.toInt() ?? 0;
            final createdAt = entry['created_at'] != null
                ? DateTime.tryParse(entry['created_at'] as String)
                : null;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(
                  _actionIcon(action),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                description.isNotEmpty ? description : action,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: createdAt != null
                  ? Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                      style: const TextStyle(fontSize: 11),
                    )
                  : null,
              trailing: Text(
                '+${Formatters.formatPoints(points)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _actionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'listing':
        return Icons.home_work_outlined;
      case 'referral':
        return Icons.person_add_alt_1_outlined;
      case 'bonus':
        return Icons.card_giftcard_rounded;
      case 'login':
        return Icons.login_rounded;
      default:
        return Icons.stars_rounded;
    }
  }
}

// =============================================================================
// Bonuses tab
// =============================================================================

class _BonusesTab extends ConsumerWidget {
  const _BonusesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bonusAsync = ref.watch(bonusHistoryProvider);

    return bonusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(bonusHistoryProvider),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const _EmptyView(
            icon: Icons.card_giftcard_rounded,
            message: 'No bonuses received yet',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final type = entry['type'] as String? ?? 'Bonus';
            final amountUsd = (entry['amount_usd'] as num?)?.toDouble() ?? 0;
            final status = entry['status'] as String? ?? 'pending';
            final period = entry['period'] as String? ?? '';
            final periodStart = entry['period_start'] as String?;
            final periodEnd = entry['period_end'] as String?;

            String periodLabel = period;
            if (periodStart != null && periodEnd != null) {
              final start = DateTime.tryParse(periodStart);
              final end = DateTime.tryParse(periodEnd);
              if (start != null && end != null) {
                periodLabel =
                    '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
              }
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceVariant,
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              title: Text(
                _formatBonusType(type),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(periodLabel, style: const TextStyle(fontSize: 11)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatUSD(amountUsd),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _StatusBadge(status: status),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatBonusType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}

// =============================================================================
// Withdrawals tab
// =============================================================================

class _WithdrawalsTab extends ConsumerWidget {
  const _WithdrawalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalAsync = ref.watch(withdrawalHistoryProvider);

    return withdrawalAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(withdrawalHistoryProvider),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const _EmptyView(
            icon: Icons.account_balance_wallet_outlined,
            message: 'No withdrawals yet',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final requestedPoints =
                (entry['requested_points'] as num?)?.toInt() ?? 0;
            final amountUsd = (entry['amount_usd'] as num?)?.toDouble() ?? 0;
            final amountBdt = (entry['amount_bdt'] as num?)?.toDouble() ?? 0;
            final method = entry['method'] as String? ?? '';
            final status = entry['status'] as String? ?? 'pending';
            final createdAt = entry['created_at'] != null
                ? DateTime.tryParse(entry['created_at'] as String)
                : null;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(
                  method.toLowerCase() == 'bkash'
                      ? Icons.phone_android
                      : Icons.account_balance,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                requestedPoints > 0
                    ? '${Formatters.formatPoints(requestedPoints)}  •  ${Formatters.formatUSD(amountUsd)}'
                    : '${Formatters.formatUSD(amountUsd)}  (${Formatters.formatBDT(amountBdt)})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.formatBDT(amountBdt),
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    'via ${method.toUpperCase()}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (createdAt != null)
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
              trailing: _StatusBadge(status: status),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// Shared helper widgets
// =============================================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'approved':
        backgroundColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        break;
      case 'pending':
        backgroundColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        break;
      case 'rejected':
      case 'failed':
        backgroundColor = AppColors.error.withValues(alpha: 0.15);
        textColor = AppColors.error;
        break;
      default:
        backgroundColor = AppColors.info.withValues(alpha: 0.15);
        textColor = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
