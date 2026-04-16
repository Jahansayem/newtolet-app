import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/team_member.dart';
import '../../providers/team_tree_provider.dart';
import 'activity_status_dot.dart';
import 'star_level_badge.dart';

/// A single expandable tree node in the team tree view.
///
/// Shows the member's avatar, name, star badge, PPV, join date, and an
/// activity status dot. When tapped, expands to reveal direct referrals
/// (lazy loaded via [teamTreeProvider]).
class TreeNodeWidget extends ConsumerStatefulWidget {
  const TreeNodeWidget({
    required this.member,
    required this.depth,
    this.onProfileTap,
    super.key,
  });

  final TeamMember member;
  final int depth;

  /// Called when the user taps the member's name or avatar for a mini profile.
  final ValueChanged<TeamMember>? onProfileTap;

  @override
  ConsumerState<TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends ConsumerState<TreeNodeWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isLoading = false;
  List<TeamMember> _children = [];

  static final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    // Check if children were previously cached.
    final cached =
        ref.read(teamTreeProvider.notifier).getCachedChildren(widget.member.userId);
    if (cached != null && cached.isNotEmpty) {
      _children = cached;
    }
  }

  Future<void> _toggleExpand() async {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      return;
    }

    // Load children if not yet cached.
    final notifier = ref.read(teamTreeProvider.notifier);
    if (!notifier.hasLoadedChildren(widget.member.userId)) {
      setState(() => _isLoading = true);
      try {
        final children =
            await notifier.loadChildren(widget.member.userId);
        if (mounted) {
          setState(() {
            _children = children;
            _isLoading = false;
            _isExpanded = true;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      _children = notifier.getCachedChildren(widget.member.userId) ?? [];
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final indentPadding = widget.depth * 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main node row
        InkWell(
          onTap: _toggleExpand,
          child: Padding(
            padding: EdgeInsets.only(
              left: indentPadding,
              right: 12,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => widget.onProfileTap?.call(member),
                  child: _buildAvatar(member),
                ),
                const SizedBox(width: 12),

                // Name + subtitle
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onProfileTap?.call(member),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row with star badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            StarLevelBadge(
                              starLevel: member.starLevel,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // PPV + join date
                        Text(
                          'PPV: ${member.ppv}'
                          '${member.joinedAt != null ? ' \u2022 Joined: ${_dateFormat.format(member.joinedAt!)}' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Activity status dot
                ActivityStatusDot(status: member.activityStatus),

                const SizedBox(width: 8),

                // Expand / collapse arrow or loading spinner
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Divider
        Padding(
          padding: EdgeInsets.only(left: indentPadding + 52),
          child: const Divider(height: 1),
        ),

        // Children (when expanded)
        if (_isExpanded)
          ..._children.map(
            (child) => TreeNodeWidget(
              member: child,
              depth: widget.depth + 1,
              onProfileTap: widget.onProfileTap,
            ),
          ),

        // Empty state when expanded but no children
        if (_isExpanded && _children.isEmpty && !_isLoading)
          Padding(
            padding: EdgeInsets.only(
              left: indentPadding + 52,
              top: 8,
              bottom: 8,
            ),
            child: const Text(
              'No referrals yet',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(TeamMember member) {
    if (member.profileImageUrl != null &&
        member.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage:
            CachedNetworkImageProvider(member.profileImageUrl!),
        backgroundColor: AppColors.surfaceVariant,
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        member.initials,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
