import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/providers/current_user_provider.dart';
import '../../models/invite_model.dart';
import '../../models/upgrade_assistant_model.dart';
import '../../providers/invite_provider.dart';
import '../../providers/upgrade_assistant_provider.dart';

/// Screen for sharing the user's referral code, copying the invite link,
/// sending invite emails, and viewing invite history.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _buildReferralLink(String referralCode) {
    return 'https://newtolet.com/join?ref=$referralCode';
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    try {
      await ref
          .read(inviteListProvider.notifier)
          .createInvite(_emailController.text.trim());
      ref.invalidate(inviteStatsProvider);

      if (mounted) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invite: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final invitesAsync = ref.watch(inviteListProvider);
    final statsAsync = ref.watch(inviteStatsProvider);
    final upgradeAsync = ref.watch(upgradeAssistantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(inviteListProvider.notifier).refresh();
              ref.invalidate(inviteStatsProvider);
              ref.invalidate(upgradeAssistantProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please sign in to continue.'));
          }

          final referralCode = user.referralCode ?? 'N/A';
          final referralLink = _buildReferralLink(referralCode);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // ----------------------------------------------------------
              // Stats bar
              // ----------------------------------------------------------
              statsAsync.when(
                loading: () => const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (stats) => _InviteStatsBar(stats: stats),
              ),

              const SizedBox(height: 16),

              upgradeAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (data) => _ReferralEligibilityCard(data: data),
              ),

              const SizedBox(height: 20),

              // ----------------------------------------------------------
              // Referral code card
              // ----------------------------------------------------------
              _ReferralCodeCard(
                referralCode: referralCode,
                onCopy: () => _copyToClipboard(referralCode, 'Referral code'),
              ),

              const SizedBox(height: 20),

              _ReferralLinkCard(
                referralLink: referralLink,
                onCopyLink: () {
                  _copyToClipboard(referralLink, 'Referral link');
                },
              ),

              const SizedBox(height: 24),

              // ----------------------------------------------------------
              // Invite via email
              // ----------------------------------------------------------
              Text(
                'Invite via Email',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Enter email address',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                          isDense: true,
                        ),
                        validator: Validators.validateEmail,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendInvite,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Send'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ----------------------------------------------------------
              // Invite history
              // ----------------------------------------------------------
              Text(
                'Invite History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              invitesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading invites: $e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                data: (invites) {
                  if (invites.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: const Center(
                        child: Text(
                          'No invites sent yet.\nStart sharing your referral code!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invites.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _InviteListTile(invite: invites[index]);
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats bar
// ---------------------------------------------------------------------------

class _InviteStatsBar extends StatelessWidget {
  const _InviteStatsBar({required this.stats});

  final InviteStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            label: 'Total Invites',
            value: '${stats.totalInvites}',
            color: AppColors.primary,
          ),
          Container(width: 1, height: 32, color: AppColors.border),
          _StatColumn(
            label: 'Registered',
            value: '${stats.registeredCount}',
            color: AppColors.statusCommon,
          ),
          Container(width: 1, height: 32, color: AppColors.border),
          _StatColumn(
            label: 'Completed',
            value: '${stats.completedCount}',
            color: AppColors.statusActive,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ReferralEligibilityCard extends StatelessWidget {
  const _ReferralEligibilityCard({required this.data});

  final UpgradeAssistantData data;

  @override
  Widget build(BuildContext context) {
    final color = data.isReferralEligible
        ? AppColors.success
        : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.isReferralEligible ? Icons.check_circle : Icons.lock_outline,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.isReferralEligible
                      ? 'Referral bonus is active'
                      : 'Referral bonus is locked',
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  data.isReferralEligible
                      ? 'You now earn ${data.formattedReferralPoints} points for each completed referral.'
                      : 'Complete ${data.remainingListingsForReferral} more approved listings to unlock ${data.formattedReferralPoints} points per referral.',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current progress: ${data.approvedListings}/${data.referralUnlockListings} approved listings',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Referral code card
// ---------------------------------------------------------------------------

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({required this.referralCode, required this.onCopy});

  final String referralCode;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surfaceVariant,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Referral Code',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  referralCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy, color: AppColors.primary),
            tooltip: 'Copy code',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralLinkCard extends StatelessWidget {
  const _ReferralLinkCard({
    required this.referralLink,
    required this.onCopyLink,
  });

  final String referralLink;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Referral Link',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          SelectableText(
            referralLink,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCopyLink,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Copy Link'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Invite list tile
// ---------------------------------------------------------------------------

class _InviteListTile extends StatelessWidget {
  const _InviteListTile({required this.invite});

  final InviteModel invite;

  static final _dateFormat = DateFormat('dd MMM yyyy');

  Color get _statusColor {
    switch (invite.status) {
      case 'registered':
        return AppColors.statusCommon;
      case 'completed':
        return AppColors.statusActive;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: _statusColor.withValues(alpha: 0.15),
        child: Icon(
          invite.status == 'completed'
              ? Icons.check_circle
              : invite.status == 'registered'
              ? Icons.person_add
              : Icons.hourglass_empty,
          color: _statusColor,
          size: 20,
        ),
      ),
      title: Text(
        invite.invitedEmail,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        invite.createdAt != null
            ? _dateFormat.format(invite.createdAt!)
            : 'Unknown date',
        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          invite.statusLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _statusColor,
          ),
        ),
      ),
    );
  }
}
