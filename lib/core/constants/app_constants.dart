/// Application-wide constants for the NewTolet MLM agent system.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // Role keys
  // ---------------------------------------------------------------------------

  static const String roleAgent = 'agent';
  static const String roleFieldOfficer = 'field_officer';
  static const String roleRemoteOfficer = 'remote_officer';

  // ---------------------------------------------------------------------------
  // Point values
  // ---------------------------------------------------------------------------

  /// Points awarded for publishing a verified listing.
  static const int pointsPerListing = 100;

  /// Points awarded for each verified listing created by a field officer.
  static const int fieldOfficerPointsPerListing = 500;

  /// Points awarded for each verified listing created by a remote officer.
  static const int remoteOfficerPointsPerListing = 100;

  /// Points awarded for each successful invite (invitee registers).
  static const int pointsPerInvite = 150;

  /// Approved listings required before referral points unlock.
  static const int minListingsForReferralBonus = 5;

  /// Bonus points when an invitee publishes their first listing.
  static const int pointsFirstListing = 50;

  /// Weekly active bonus for meeting weekly targets.
  static const int pointsWeeklyActive = 25;

  /// Bonus for a listing that achieves a quality score threshold.
  static const int pointsQuality = 30;

  // ---------------------------------------------------------------------------
  // Team milestone bonuses  (team size -> bonus points)
  // ---------------------------------------------------------------------------

  static const Map<int, int> teamMilestoneBonuses = {
    10: 200,
    25: 500,
    50: 1000,
    100: 2500,
  };

  // ---------------------------------------------------------------------------
  // Listing campaign rewards
  // ---------------------------------------------------------------------------

  static const List<ListingTargetConfig> listingTargetMilestones = [
    ListingTargetConfig(
      milestone: 'Target 1',
      targetListings: 10,
      rewardPerListing: 50,
    ),
    ListingTargetConfig(
      milestone: 'Target 2',
      targetListings: 20,
      rewardPerListing: 70,
    ),
    ListingTargetConfig(
      milestone: 'Target 3',
      targetListings: 30,
      rewardPerListing: 100,
    ),
  ];

  /// Minimum approved listings required each day to keep the streak alive.
  static const int listingStreakMinPerDay = 5;

  /// Consecutive qualifying days required to unlock the streak reward.
  static const int listingStreakDaysRequired = 30;

  /// Bonus awarded after maintaining the listing streak.
  static const int listingStreakBonusPoints = 1000;

  /// Fixed UTC offset for Bangladesh time.
  static const Duration dhakaUtcOffset = Duration(hours: 6);

  // ---------------------------------------------------------------------------
  // Star levels
  // ---------------------------------------------------------------------------

  static const StarLevelConfig startingStarLevel = StarLevelConfig(
    ppvNeeded: 0,
    teamSize: 0,
    directBonusPercent: 0,
    indirectBonusPercent: 0,
    rewardLabel: '-',
    rewardIcon: 'minus',
  );

  /// Each star level maps to a configuration holding PPV requirement,
  /// minimum team size, direct bonus percentage, and indirect bonus percentage.
  static const Map<int, StarLevelConfig> starLevels = {
    1: StarLevelConfig(
      ppvNeeded: 400,
      teamSize: 4,
      directBonusPercent: 5,
      indirectBonusPercent: 0,
      rewardLabel: '2% Bonus',
      rewardIcon: 'percent',
    ),
    2: StarLevelConfig(
      ppvNeeded: 1000,
      teamSize: 10,
      directBonusPercent: 7,
      indirectBonusPercent: 0,
      rewardLabel: '3% Bonus',
      rewardIcon: 'percent',
    ),
    3: StarLevelConfig(
      ppvNeeded: 2000,
      teamSize: 20,
      directBonusPercent: 10,
      indirectBonusPercent: 0,
      rewardLabel: '5% Bonus',
      rewardIcon: 'percent',
    ),
    4: StarLevelConfig(
      ppvNeeded: 5000,
      teamSize: 50,
      directBonusPercent: 12,
      indirectBonusPercent: 0,
      rewardLabel: 'Button Phone',
      rewardIcon: 'phone_classic',
    ),
    5: StarLevelConfig(
      ppvNeeded: 10000,
      teamSize: 100,
      directBonusPercent: 15,
      indirectBonusPercent: 0,
      rewardLabel: 'Smartphone',
      rewardIcon: 'phone',
    ),
    6: StarLevelConfig(
      ppvNeeded: 20000,
      teamSize: 200,
      directBonusPercent: 18,
      indirectBonusPercent: 0,
      rewardLabel: 'Laptop',
      rewardIcon: 'laptop',
    ),
    7: StarLevelConfig(
      ppvNeeded: 50000,
      teamSize: 500,
      directBonusPercent: 20,
      indirectBonusPercent: 0,
      rewardLabel: 'Motorcycle',
      rewardIcon: 'motorcycle',
    ),
    8: StarLevelConfig(
      ppvNeeded: 100000,
      teamSize: 1000,
      directBonusPercent: 25,
      indirectBonusPercent: 0,
      rewardLabel: 'Sedan Car',
      rewardIcon: 'car',
    ),
  };

  // ---------------------------------------------------------------------------
  // Points-to-currency conversion
  // ---------------------------------------------------------------------------

  /// 1 point = $0.000285714 USD (3500 points = $1.00).
  static const double pointsToUsd = 1 / 3500;

  /// Minimum points required before a withdrawal can be requested.
  static const int minWithdrawalPoints = 5000;

  /// Minimum USD equivalent of [minWithdrawalPoints].
  static const double minWithdrawalUsd = minWithdrawalPoints * pointsToUsd;

  /// Bangladesh calendar day where the monthly withdrawal window opens.
  static const int withdrawalWindowStartDay = 1;

  /// Bangladesh calendar day where the monthly withdrawal window closes.
  static const int withdrawalWindowEndDay = 5;

  /// Canonical timezone used for withdrawal window calculations.
  static const String withdrawalTimezone = 'Asia/Dhaka';

  // ---------------------------------------------------------------------------
  // Activity status thresholds (per calendar month)
  // ---------------------------------------------------------------------------

  /// Listings per month to qualify as Active.
  static const int activeListingsPerMonth = 20;

  /// Invites per month to qualify as Active.
  static const int activeInvitesPerMonth = 4;

  /// Lower bound of listings per month for Common status.
  static const int commonListingsMin = 10;

  /// Upper bound of listings per month for Common status.
  static const int commonListingsMax = 19;

  /// Lower bound of invites per month for Common status.
  static const int commonInvitesMin = 2;

  /// Upper bound of invites per month for Common status.
  static const int commonInvitesMax = 3;

  // ---------------------------------------------------------------------------
  // Weekly active bonus requirements
  // ---------------------------------------------------------------------------

  /// Listings required in a single week to qualify for the weekly active bonus.
  static const int weeklyActiveListings = 7;

  /// Invites required in a single week to qualify for the weekly active bonus.
  static const int weeklyActiveInvites = 1;

  static String displayRoleName(String roleKey) {
    switch (roleKey.trim().toLowerCase()) {
      case roleFieldOfficer:
        return 'Field Officer';
      case roleRemoteOfficer:
        return 'Remote Officer';
      case roleAgent:
      default:
        return 'Agent';
    }
  }

  static int defaultListingPointsForRole(String roleKey) {
    switch (roleKey.trim().toLowerCase()) {
      case roleFieldOfficer:
        return fieldOfficerPointsPerListing;
      case roleRemoteOfficer:
      case roleAgent:
      default:
        return remoteOfficerPointsPerListing;
    }
  }

  static double pointsToUsdAmount(int points) => points * pointsToUsd;

  static int usdToPoints(double usd) => (usd * 3500).floor();
}

/// Configuration for a single star level in the MLM system.
class StarLevelConfig {
  const StarLevelConfig({
    required this.ppvNeeded,
    required this.teamSize,
    required this.directBonusPercent,
    required this.indirectBonusPercent,
    required this.rewardLabel,
    required this.rewardIcon,
  });

  /// Personal Point Volume required to reach this star level.
  final int ppvNeeded;

  /// Minimum number of team members (direct + indirect).
  final int teamSize;

  /// Percentage bonus on direct referral earnings.
  final int directBonusPercent;

  /// Percentage bonus on indirect (downline) referral earnings.
  final int indirectBonusPercent;

  /// Reward users see for reaching this level.
  final String rewardLabel;

  /// Emoji fallback used in the level timeline UI.
  final String rewardIcon;
}

/// Configuration for a single listing target milestone.
class ListingTargetConfig {
  const ListingTargetConfig({
    required this.milestone,
    required this.targetListings,
    required this.rewardPerListing,
  });

  final String milestone;
  final int targetListings;
  final int rewardPerListing;

  int get totalRewardPoints => targetListings * rewardPerListing;
}
