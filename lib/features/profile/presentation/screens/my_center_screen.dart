import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/current_user_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/withdraw_sheet.dart';

/// Tab 4 of the bottom navigation -- the user's personal hub.
///
/// Displays profile information, balance, and navigation to sub-features
/// such as earnings, team tree, listings, settings, and more.
class MyCenterScreen extends ConsumerWidget {
  const MyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Center'),
        automaticallyImplyLeading: false,
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
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // -- Profile header -------------------------------------------
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ProfileHeader(user: user),
                        const SizedBox(height: 14),
                        _buildReferralCode(context, user.referralCode),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // -- Balance card ---------------------------------------------
                BalanceCard(
                  balanceUsd: user.balanceUsd,
                  onWithdraw: () => _showWithdrawSheet(context, user),
                ),
                const SizedBox(height: 24),

                // -- Menu sections --------------------------------------------
                _SectionTitle(title: 'Network'),
                _MenuTile(
                  icon: Icons.account_tree_outlined,
                  label: 'My Referral Tree',
                  onTap: () => context.goNamed(RouteNames.teamTree),
                ),
                _MenuTile(
                  icon: Icons.home_work_outlined,
                  label: 'My Listings',
                  onTap: () => context.goNamed(RouteNames.myListings),
                ),
                _MenuTile(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Invite Friends',
                  onTap: () => context.goNamed(RouteNames.invite),
                ),

                const SizedBox(height: 8),
                _SectionTitle(title: 'Account'),
                _MenuTile(
                  icon: Icons.monetization_on_outlined,
                  label: 'My Earnings',
                  onTap: () => context.goNamed(RouteNames.earnings),
                ),
                _MenuTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  onTap: () => context.goNamed(RouteNames.editProfile),
                ),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => context.goNamed(RouteNames.settings),
                ),

                const SizedBox(height: 8),
                _MenuTile(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  iconColor: AppColors.error,
                  labelColor: AppColors.error,
                  onTap: () => _confirmSignOut(context, ref),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Referral code row
  // ---------------------------------------------------------------------------

  Widget _buildReferralCode(BuildContext context, String? referralCode) {
    if (referralCode == null || referralCode.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            'Referral: $referralCode',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              Clipboard.setData(ClipboardData(text: referralCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Referral code copied'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.copy, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Withdraw bottom sheet
  // ---------------------------------------------------------------------------

  void _showWithdrawSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WithdrawSheet(user: user),
    );
  }

  // ---------------------------------------------------------------------------
  // Sign out confirmation
  // ---------------------------------------------------------------------------

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.textHint,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.primary),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: labelColor ?? AppColors.textPrimary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: iconColor ?? AppColors.textHint,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
