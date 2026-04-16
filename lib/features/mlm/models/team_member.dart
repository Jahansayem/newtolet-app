import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A member in the MLM sponsor tree, returned by the `get_direct_referrals`
/// and `get_sponsor_downline` Supabase RPC functions.
class TeamMember {
  const TeamMember({
    required this.userId,
    required this.name,
    required this.starLevel,
    required this.activityStatus,
    required this.ppv,
    this.profileImageUrl,
    this.joinedAt,
    this.depth = 1,
    this.sponsorId,
  });

  final String userId;
  final String name;
  final int starLevel;
  final String activityStatus;
  final int ppv;
  final String? profileImageUrl;
  final DateTime? joinedAt;
  final int depth;
  final String? sponsorId;

  /// Maps the `activity_status` column value to a display colour.
  Color get activityColor {
    switch (activityStatus) {
      case 'active':
        return AppColors.statusActive;
      case 'common':
        return AppColors.statusCommon;
      case 'low_active':
      default:
        return AppColors.statusLowActive;
    }
  }

  /// Returns a user-friendly label for the activity status.
  String get activityLabel {
    switch (activityStatus) {
      case 'active':
        return 'Active';
      case 'common':
        return 'Common';
      case 'low_active':
      default:
        return 'Low Active';
    }
  }

  /// Returns the user's initials (up to 2 characters) for avatar fallback.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      starLevel: (json['star_level'] as num?)?.toInt() ?? 0,
      activityStatus: json['activity_status'] as String? ?? 'low_active',
      ppv: (json['ppv'] as num?)?.toInt() ?? 0,
      profileImageUrl: json['profile_image_url'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String)
          : null,
      depth: (json['depth'] as num?)?.toInt() ?? 1,
      sponsorId: json['sponsor_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'star_level': starLevel,
      'activity_status': activityStatus,
      'ppv': ppv,
      'profile_image_url': profileImageUrl,
      'joined_at': joinedAt?.toIso8601String(),
      'depth': depth,
      'sponsor_id': sponsorId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'TeamMember(userId: $userId, name: $name, star: $starLevel)';
}
