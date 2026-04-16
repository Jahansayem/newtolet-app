import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_model.dart';

/// Reusable profile header displaying avatar, name, email, star level badge,
/// and activity status indicator.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.user,
    super.key,
  });

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // -- Avatar -----------------------------------------------------------
        _buildAvatar(),
        const SizedBox(width: 14),

        // -- Name, email, badges ---------------------------------------------
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.name ?? 'NewTolet Agent',
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActivityDot(),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 6),
              _buildStarBadge(context),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Avatar
  // ---------------------------------------------------------------------------

  Widget _buildAvatar() {
    final initials = _getInitials();
    final hasImage =
        user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primaryLight,
      child: hasImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.profileImageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (context, url) => _initialsWidget(initials),
                errorWidget: (context, url, error) =>
                    _initialsWidget(initials),
              ),
            )
          : _initialsWidget(initials),
    );
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }

  String _getInitials() {
    final name = user.name ?? user.email;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ---------------------------------------------------------------------------
  // Activity dot
  // ---------------------------------------------------------------------------

  Widget _buildActivityDot() {
    Color dotColor;
    switch (user.activityStatus) {
      case 'active':
        dotColor = AppColors.statusActive;
        break;
      case 'common':
        dotColor = AppColors.statusCommon;
        break;
      default:
        dotColor = AppColors.statusLowActive;
    }

    return Semantics(
      label: 'Activity status: ${user.activityStatus}',
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dotColor,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Star badge
  // ---------------------------------------------------------------------------

  Widget _buildStarBadge(BuildContext context) {
    final level = user.starLevel.clamp(0, AppColors.starGradients.length - 1);
    final gradientColors = AppColors.starGradients[level];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 14,
            color: level >= 6 ? AppColors.textPrimary : AppColors.onPrimary,
          ),
          const SizedBox(width: 3),
          Text(
            'Star $level',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: level >= 6 ? AppColors.textPrimary : AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
