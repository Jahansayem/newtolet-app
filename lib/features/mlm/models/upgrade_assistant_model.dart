import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/listing_role_model.dart';
import '../../../shared/models/user_model.dart';

class UpgradeAssistantData {
  const UpgradeAssistantData({
    required this.roleKey,
    required this.roleLabel,
    required this.pointsPerListing,
    required this.referralPoints,
    required this.referralUnlockListings,
    required this.currentStarLevel,
    required this.ppv,
    required this.teamSize,
    required this.approvedListings,
    required this.dailyListingCounts,
    required this.streakReferenceTime,
    required this.currentConfig,
    required this.nextStarLevel,
    required this.nextConfig,
  });

  factory UpgradeAssistantData.fromInputs({
    required UserModel user,
    required int teamSize,
    required int approvedListings,
    List<ListingDailyCount> dailyListingCounts = const [],
    ListingRoleModel? roleConfig,
    DateTime? now,
  }) {
    final roleKey = user.role.trim().toLowerCase();
    final currentStarLevel = user.starLevel.clamp(0, 8).toInt();
    final currentConfig = AppConstants.starLevels[currentStarLevel];
    final nextStarLevel = currentStarLevel >= 8 ? null : currentStarLevel + 1;
    final nextConfig = nextStarLevel == null
        ? null
        : AppConstants.starLevels[nextStarLevel];

    return UpgradeAssistantData(
      roleKey: roleKey,
      roleLabel:
          roleConfig?.displayName ?? AppConstants.displayRoleName(roleKey),
      pointsPerListing:
          roleConfig?.pointsPerListing ??
          AppConstants.defaultListingPointsForRole(roleKey),
      referralPoints: AppConstants.pointsPerInvite,
      referralUnlockListings: AppConstants.minListingsForReferralBonus,
      currentStarLevel: currentStarLevel,
      ppv: user.ppv,
      teamSize: teamSize,
      approvedListings: approvedListings,
      dailyListingCounts: dailyListingCounts,
      streakReferenceTime: now ?? DateTime.now().toUtc(),
      currentConfig: currentConfig,
      nextStarLevel: nextStarLevel,
      nextConfig: nextConfig,
    );
  }

  final String roleKey;
  final String roleLabel;
  final int pointsPerListing;
  final int referralPoints;
  final int referralUnlockListings;
  final int currentStarLevel;
  final int ppv;
  final int teamSize;
  final int approvedListings;
  final List<ListingDailyCount> dailyListingCounts;
  final DateTime streakReferenceTime;
  final StarLevelConfig? currentConfig;
  final int? nextStarLevel;
  final StarLevelConfig? nextConfig;

  StarLevelConfig get resolvedCurrentConfig =>
      currentConfig ?? AppConstants.startingStarLevel;

  bool get isMaxLevel => nextConfig == null;

  bool get isReferralEligible => approvedListings >= referralUnlockListings;

  int get remainingListingsForReferral =>
      math.max(0, referralUnlockListings - approvedListings);

  int get remainingPpvForNext =>
      nextConfig == null ? 0 : math.max(0, nextConfig!.ppvNeeded - ppv);

  int get remainingTeamSizeForNext =>
      nextConfig == null ? 0 : math.max(0, nextConfig!.teamSize - teamSize);

  int get currentDirectBonusPercent => currentConfig?.directBonusPercent ?? 0;

  int get currentIndirectBonusPercent =>
      currentConfig?.indirectBonusPercent ?? 0;

  int get nextDirectBonusPercent => nextConfig?.directBonusPercent ?? 0;

  int get nextIndirectBonusPercent => nextConfig?.indirectBonusPercent ?? 0;

  bool get unlocksLeadershipBonus =>
      nextStarLevel != null && nextStarLevel! >= 4 && currentStarLevel < 4;

  double get ppvProgressToNext {
    if (nextConfig == null) return 1;

    final currentPpvFloor = currentConfig?.ppvNeeded ?? 0;
    final segment = nextConfig!.ppvNeeded - currentPpvFloor;
    if (segment <= 0) return 1;

    final progressed = (ppv - currentPpvFloor) / segment;
    return progressed.clamp(0, 1).toDouble();
  }

  double get teamProgressToNext {
    if (nextConfig == null) return 1;

    final currentTeamFloor = currentConfig?.teamSize ?? 0;
    final segment = nextConfig!.teamSize - currentTeamFloor;
    if (segment <= 0) return 1;

    final progressed = (teamSize - currentTeamFloor) / segment;
    return progressed.clamp(0, 1).toDouble();
  }

  double get overallProgressToNext =>
      math.min(ppvProgressToNext, teamProgressToNext).toDouble();

  int get overallProgressPercent => (overallProgressToNext * 100).round();

  String get currentLevelLabel =>
      currentStarLevel == 0 ? 'New' : 'Star $currentStarLevel';

  String get nextLevelLabel =>
      nextStarLevel == null ? 'Top level reached' : 'Star $nextStarLevel';

  String get currentLevelMemberLabel =>
      currentStarLevel == 0 ? 'New Member' : 'Star $currentStarLevel Member';

  String get formattedPpv =>
      Formatters.formatPoints(ppv).replaceAll(' pts', '');

  String get formattedPointsPerListing =>
      Formatters.formatPoints(pointsPerListing).replaceAll(' pts', '');

  String get formattedReferralPoints =>
      Formatters.formatPoints(referralPoints).replaceAll(' pts', '');

  String get currentRewardLabel => resolvedCurrentConfig.rewardLabel;

  String get currentRewardIcon => resolvedCurrentConfig.rewardIcon;

  String get nextRewardLabel =>
      nextConfig?.rewardLabel ?? resolvedCurrentConfig.rewardLabel;

  List<ListingTargetProgressData> get listingTargetMilestones {
    final configs = AppConstants.listingTargetMilestones;
    final firstIncompleteIndex = configs.indexWhere(
      (config) => approvedListings < config.targetListings,
    );

    return List<ListingTargetProgressData>.generate(configs.length, (index) {
      final config = configs[index];
      final status = firstIncompleteIndex == -1
          ? ListingTargetStatus.completed
          : index < firstIncompleteIndex
          ? ListingTargetStatus.completed
          : index == firstIncompleteIndex
          ? ListingTargetStatus.current
          : ListingTargetStatus.locked;

      return ListingTargetProgressData(
        milestone: config.milestone,
        targetListings: config.targetListings,
        rewardPerListing: config.rewardPerListing,
        totalTargetValue: config.totalRewardPoints,
        progressListings: math.min(approvedListings, config.targetListings),
        status: status,
      );
    });
  }

  int get completedListingTargetCount => listingTargetMilestones
      .where((milestone) => milestone.status == ListingTargetStatus.completed)
      .length;

  ListingTargetProgressData? get currentListingTarget {
    for (final milestone in listingTargetMilestones) {
      if (milestone.status == ListingTargetStatus.current) {
        return milestone;
      }
    }
    return null;
  }

  int get listingTargetProgressPercent {
    final finalTarget =
        AppConstants.listingTargetMilestones.last.targetListings;
    if (finalTarget == 0) return 100;
    return ((approvedListings / finalTarget).clamp(0, 1) * 100).round();
  }

  String get listingTargetProgressLabel {
    final currentTarget = currentListingTarget;
    if (currentTarget == null) {
      return 'All listing targets completed.';
    }

    final remaining = math.max(
      0,
      currentTarget.targetListings - approvedListings,
    );
    return remaining == 0
        ? '${currentTarget.milestone} unlocked.'
        : '$remaining more approved listings to unlock ${currentTarget.milestone}.';
  }

  DateTime get streakReferenceDay => _dhakaDay(streakReferenceTime);

  int get streakMinimumPerDay => AppConstants.listingStreakMinPerDay;

  int get streakDaysRequired => AppConstants.listingStreakDaysRequired;

  int get streakBonusPoints => AppConstants.listingStreakBonusPoints;

  Map<DateTime, int> get _dailyListingCountMap {
    final counts = <DateTime, int>{};
    for (final dailyCount in dailyListingCounts) {
      final normalizedDay = _dhakaDay(dailyCount.day);
      counts[normalizedDay] = dailyCount.count;
    }
    return counts;
  }

  int get currentQualifyingStreakDays {
    final counts = _dailyListingCountMap;
    var streak = 0;

    for (var offset = 0; offset < streakDaysRequired; offset++) {
      final day = streakReferenceDay.subtract(Duration(days: offset));
      final count = counts[day] ?? 0;
      if (count < streakMinimumPerDay) {
        break;
      }
      streak++;
    }

    return streak;
  }

  bool get streakQualified => currentQualifyingStreakDays >= streakDaysRequired;

  int get remainingDaysForStreak =>
      math.max(0, streakDaysRequired - currentQualifyingStreakDays);

  double get streakProgress =>
      (currentQualifyingStreakDays / streakDaysRequired).clamp(0, 1).toDouble();

  String get formattedStreakBonusPoints =>
      Formatters.formatPoints(streakBonusPoints).replaceAll(' pts', '');

  String get streakSummary {
    if (streakQualified) {
      return '30-day streak complete. Monthly bonus unlocked.';
    }

    return '$remainingDaysForStreak more qualifying day${remainingDaysForStreak == 1 ? '' : 's'} needed for the monthly bonus.';
  }

  String get streakRuleLabel =>
      '$streakMinimumPerDay listings/day for $streakDaysRequired days';

  String get nextLevelRequirementSummary {
    if (isMaxLevel) {
      return 'You already unlocked the highest star tier.';
    }

    final requirements = <String>[];
    if (remainingPpvForNext > 0) {
      requirements.add(
        '${Formatters.formatPoints(remainingPpvForNext).replaceAll(' pts', '')} more PPV',
      );
    }
    if (remainingTeamSizeForNext > 0) {
      requirements.add('$remainingTeamSizeForNext more team members');
    }

    final requirementText = requirements.isEmpty
        ? 'the final requirement'
        : requirements.join(' and ');
    return 'Add $requirementText to reach $nextLevelLabel and unlock $nextRewardLabel.';
  }

  List<RewardLevelCardData> get timelineLevels {
    final cards = <RewardLevelCardData>[
      RewardLevelCardData(
        level: 0,
        title: 'Level: None (New)',
        subtitle: 'Welcome tier',
        rewardLabel: AppConstants.startingStarLevel.rewardLabel,
        rewardIcon: AppConstants.startingStarLevel.rewardIcon,
        teamSizeRequired: 0,
        ppvRequired: 0,
        directBonusPercent: 0,
        indirectBonusPercent: 0,
        status: _statusForLevel(0),
      ),
    ];

    final entries = AppConstants.starLevels.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      final config = entry.value;
      cards.add(
        RewardLevelCardData(
          level: entry.key,
          title: 'Star ${entry.key}',
          subtitle:
              '${Formatters.formatPoints(config.ppvNeeded).replaceAll(' pts', '')} PPV / ${config.teamSize} team',
          rewardLabel: config.rewardLabel,
          rewardIcon: config.rewardIcon,
          teamSizeRequired: config.teamSize,
          ppvRequired: config.ppvNeeded,
          directBonusPercent: config.directBonusPercent,
          indirectBonusPercent: config.indirectBonusPercent,
          status: _statusForLevel(entry.key),
        ),
      );
    }

    return cards;
  }

  RewardLevelStatus _statusForLevel(int level) {
    if (level < currentStarLevel) {
      return RewardLevelStatus.completed;
    }
    if (level == currentStarLevel) {
      return RewardLevelStatus.current;
    }
    return RewardLevelStatus.locked;
  }

  static DateTime _dhakaDay(DateTime timestamp) {
    final shifted = timestamp.toUtc().add(AppConstants.dhakaUtcOffset);
    return DateTime.utc(shifted.year, shifted.month, shifted.day);
  }
}

class ListingDailyCount {
  const ListingDailyCount({required this.day, required this.count});

  final DateTime day;
  final int count;
}

enum ListingTargetStatus { completed, current, locked }

class ListingTargetProgressData {
  const ListingTargetProgressData({
    required this.milestone,
    required this.targetListings,
    required this.rewardPerListing,
    required this.totalTargetValue,
    required this.progressListings,
    required this.status,
  });

  final String milestone;
  final int targetListings;
  final int rewardPerListing;
  final int totalTargetValue;
  final int progressListings;
  final ListingTargetStatus status;

  bool get isCompleted => status == ListingTargetStatus.completed;

  bool get isCurrent => status == ListingTargetStatus.current;

  bool get isLocked => status == ListingTargetStatus.locked;

  int get remainingListings => math.max(0, targetListings - progressListings);

  String get statusLabel {
    switch (status) {
      case ListingTargetStatus.completed:
        return 'Completed';
      case ListingTargetStatus.current:
        return 'In Progress';
      case ListingTargetStatus.locked:
        return 'Locked';
    }
  }
}

enum RewardLevelStatus { completed, current, locked }

class RewardLevelCardData {
  const RewardLevelCardData({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.rewardLabel,
    required this.rewardIcon,
    required this.teamSizeRequired,
    required this.ppvRequired,
    required this.directBonusPercent,
    required this.indirectBonusPercent,
    required this.status,
  });

  final int level;
  final String title;
  final String subtitle;
  final String rewardLabel;
  final String rewardIcon;
  final int teamSizeRequired;
  final int ppvRequired;
  final int directBonusPercent;
  final int indirectBonusPercent;
  final RewardLevelStatus status;

  bool get isCompleted => status == RewardLevelStatus.completed;

  bool get isCurrent => status == RewardLevelStatus.current;

  bool get isLocked => status == RewardLevelStatus.locked;

  String get statusLabel {
    switch (status) {
      case RewardLevelStatus.completed:
        return 'Completed';
      case RewardLevelStatus.current:
        return 'Active';
      case RewardLevelStatus.locked:
        return 'Locked';
    }
  }
}
