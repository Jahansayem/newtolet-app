import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/current_user_provider.dart';
import '../../data/profile_repository.dart';
import '../../domain/withdrawal_policy.dart';
import '../../providers/profile_provider.dart';

class WithdrawSheet extends ConsumerStatefulWidget {
  const WithdrawSheet({required this.user, super.key});

  final UserModel user;

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  late final TextEditingController _pointsController;
  late final TextEditingController _accountController;
  late String _selectedMethod;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _pointsController = TextEditingController();
    _selectedMethod = _defaultMethod();
    _accountController = TextEditingController(
      text: _savedAccountFor(_selectedMethod) ?? '',
    );
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final withdrawalsAsync = ref.watch(withdrawalHistoryProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: withdrawalsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load withdrawal status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          data: (withdrawals) {
            final now = DateTime.now().toUtc();
            final availablePoints = WithdrawalPolicy.requestablePoints(
              balanceUsd: widget.user.balanceUsd,
              withdrawals: withdrawals,
            );
            final requestError = _validationMessage(
              withdrawals: withdrawals,
              now: now,
              availablePoints: availablePoints,
            );
            final currentMonthRequest = _currentMonthRequest(withdrawals, now);

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Withdraw Points',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Requests are accepted only from day '
                    '${AppConstants.withdrawalWindowStartDay} to '
                    '${AppConstants.withdrawalWindowEndDay} each month in '
                    '${AppConstants.withdrawalTimezone}.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          label: 'Requestable now',
                          value: Formatters.formatPoints(availablePoints),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          label: 'Minimum',
                          value: Formatters.formatPoints(
                            AppConstants.minWithdrawalPoints,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          label: 'This month',
                          value: currentMonthRequest == null
                              ? 'Open'
                              : _statusLabel(
                                  currentMonthRequest['status'] as String?,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Withdrawal method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'bkash', child: Text('bKash')),
                      DropdownMenuItem(value: 'nagad', child: Text('Nagad')),
                    ],
                    onChanged: _submitting
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedMethod = value;
                              _accountController.text =
                                  _savedAccountFor(value) ?? '';
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _accountController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Account number',
                      hintText: _selectedMethod == 'bkash'
                          ? '01XXXXXXXXX'
                          : '01XXXXXXXXX',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pointsController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Points to withdraw',
                      hintText: '${AppConstants.minWithdrawalPoints} or more',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimated payout: ${_estimatedPayoutLabel()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (requestError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        requestError,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: requestError != null || _submitting
                              ? null
                              : () => _submit(
                                  context: context,
                                  availablePoints: availablePoints,
                                  withdrawals: withdrawals,
                                ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _defaultMethod() {
    if ((widget.user.bkashNumber ?? '').trim().isNotEmpty) {
      return 'bkash';
    }
    return 'nagad';
  }

  Map<String, dynamic>? _currentMonthRequest(
    List<Map<String, dynamic>> withdrawals,
    DateTime now,
  ) {
    final currentDhaka = WithdrawalPolicy.toDhaka(now);
    for (final withdrawal in withdrawals) {
      final rawCreatedAt = withdrawal['created_at'] as String?;
      final createdAt = rawCreatedAt == null
          ? null
          : DateTime.tryParse(rawCreatedAt);
      if (createdAt == null) {
        continue;
      }

      final createdDhaka = WithdrawalPolicy.toDhaka(createdAt);
      if (createdDhaka.year == currentDhaka.year &&
          createdDhaka.month == currentDhaka.month) {
        return withdrawal;
      }
    }
    return null;
  }

  String? _savedAccountFor(String method) {
    switch (method) {
      case 'bkash':
        return widget.user.bkashNumber?.trim().isEmpty ?? true
            ? null
            : widget.user.bkashNumber?.trim();
      case 'nagad':
        return widget.user.nagadNumber?.trim().isEmpty ?? true
            ? null
            : widget.user.nagadNumber?.trim();
      default:
        return null;
    }
  }

  String _estimatedPayoutLabel() {
    final requestedPoints = int.tryParse(_pointsController.text.trim()) ?? 0;
    if (requestedPoints <= 0) {
      return '${Formatters.formatUSD(0)} (${Formatters.formatBDT(0)})';
    }

    final estimatedUsd = WithdrawalPolicy.pointsToUsd(requestedPoints);
    return '${Formatters.formatUSD(estimatedUsd)} (rate locked on submit)';
  }

  String? _validationMessage({
    required List<Map<String, dynamic>> withdrawals,
    required DateTime now,
    required int availablePoints,
  }) {
    if (!WithdrawalPolicy.isWindowOpen(now)) {
      return 'Withdrawals are available only from day '
          '${AppConstants.withdrawalWindowStartDay} to '
          '${AppConstants.withdrawalWindowEndDay} in '
          '${AppConstants.withdrawalTimezone}.';
    }

    if (WithdrawalPolicy.hasMonthlyRequest(withdrawals, now)) {
      return 'You already submitted a withdrawal request for '
          '${WithdrawalPolicy.monthLabel(now)}.';
    }

    if (availablePoints < AppConstants.minWithdrawalPoints) {
      return 'You need at least '
          '${Formatters.formatPoints(AppConstants.minWithdrawalPoints)} '
          'available to request a withdrawal.';
    }

    final requestedPoints = int.tryParse(_pointsController.text.trim());
    if (requestedPoints == null) {
      return 'Enter the number of points you want to withdraw.';
    }

    if (requestedPoints < AppConstants.minWithdrawalPoints) {
      return 'Minimum withdrawal is '
          '${Formatters.formatPoints(AppConstants.minWithdrawalPoints)}.';
    }

    if (requestedPoints > availablePoints) {
      return 'You can request up to ${Formatters.formatPoints(availablePoints)} '
          'right now.';
    }

    if (_accountController.text.trim().isEmpty) {
      return 'Enter the ${_selectedMethod == 'bkash' ? 'bKash' : 'Nagad'} '
          'account number for this payout.';
    }

    return null;
  }

  Future<void> _submit({
    required BuildContext context,
    required int availablePoints,
    required List<Map<String, dynamic>> withdrawals,
  }) async {
    final now = DateTime.now().toUtc();
    final message = _validationMessage(
      withdrawals: withdrawals,
      now: now,
      availablePoints: availablePoints,
    );
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final requestedPoints = int.parse(_pointsController.text.trim());

    setState(() {
      _submitting = true;
    });

    try {
      await ref
          .read(profileRepositoryProvider)
          .requestWithdrawal(
            requestedPoints: requestedPoints,
            method: _selectedMethod,
            accountNumber: _accountController.text.trim(),
          );

      ref.invalidate(withdrawalHistoryProvider);
      ref.invalidate(currentUserProvider);

      if (!context.mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Withdrawal request for ${Formatters.formatPoints(requestedPoints)} '
            'submitted.',
          ),
        ),
      );
    } on PostgrestException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String _statusLabel(String? status) {
    final normalized = (status ?? 'pending').trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'Pending';
    }
    return normalized[0].toUpperCase() + normalized.substring(1);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
