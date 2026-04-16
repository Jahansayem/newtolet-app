import 'package:flutter_test/flutter_test.dart';
import 'package:newtolet/features/mlm/models/upgrade_assistant_model.dart';
import 'package:newtolet/shared/models/user_model.dart';

void main() {
  group('UpgradeAssistantData', () {
    List<ListingDailyCount> qualifyingCounts({
      required DateTime todayUtc,
      int days = 30,
      int count = 5,
    }) {
      return List<ListingDailyCount>.generate(days, (index) {
        final day = todayUtc.subtract(Duration(days: index));
        return ListingDailyCount(day: day, count: count);
      });
    }

    test('builds timeline with completed, current, and locked levels', () {
      const user = UserModel(
        id: 'user-1',
        email: 'agent@example.com',
        role: 'agent',
        starLevel: 3,
        ppv: 1400,
      );

      final data = UpgradeAssistantData.fromInputs(
        user: user,
        teamSize: 12,
        approvedListings: 6,
      );

      final levels = data.timelineLevels;
      expect(levels.first.title, 'Level: None (New)');
      expect(levels[0].status, RewardLevelStatus.completed);
      expect(levels[1].status, RewardLevelStatus.completed);
      expect(levels[3].status, RewardLevelStatus.current);
      expect(levels[4].status, RewardLevelStatus.locked);
      expect(data.currentRewardLabel, '5% Bonus');
      expect(data.nextRewardLabel, 'Button Phone');
    });

    test('uses starting tier metadata for a new member', () {
      const user = UserModel(
        id: 'user-2',
        email: 'new@example.com',
        role: 'agent',
        starLevel: 0,
        ppv: 0,
      );

      final data = UpgradeAssistantData.fromInputs(
        user: user,
        teamSize: 0,
        approvedListings: 1,
      );

      expect(data.currentLevelMemberLabel, 'New Member');
      expect(data.currentRewardLabel, '-');
      expect(data.timelineLevels.first.status, RewardLevelStatus.current);
      expect(
        data.nextLevelRequirementSummary,
        contains('reach Star 1 and unlock 2% Bonus'),
      );
    });

    test('builds listing milestones and unlocks streak bonus at 30 days', () {
      final now = DateTime.utc(2026, 3, 19, 12);
      const user = UserModel(
        id: 'user-3',
        email: 'closer@example.com',
        role: 'agent',
        starLevel: 1,
        ppv: 450,
      );

      final data = UpgradeAssistantData.fromInputs(
        user: user,
        teamSize: 6,
        approvedListings: 20,
        dailyListingCounts: qualifyingCounts(todayUtc: now),
        now: now,
      );

      expect(
        data.listingTargetMilestones[0].status,
        ListingTargetStatus.completed,
      );
      expect(
        data.listingTargetMilestones[1].status,
        ListingTargetStatus.completed,
      );
      expect(
        data.listingTargetMilestones[2].status,
        ListingTargetStatus.current,
      );
      expect(data.listingTargetMilestones[2].totalTargetValue, 3000);
      expect(data.currentQualifyingStreakDays, 30);
      expect(data.streakQualified, isTrue);
      expect(data.streakSummary, contains('Monthly bonus unlocked'));
    });

    test('breaks streak when a day falls below the daily minimum', () {
      final now = DateTime.utc(2026, 3, 19, 12);
      const user = UserModel(
        id: 'user-4',
        email: 'gap@example.com',
        role: 'agent',
      );

      final data = UpgradeAssistantData.fromInputs(
        user: user,
        teamSize: 0,
        approvedListings: 9,
        dailyListingCounts: [
          ListingDailyCount(day: DateTime.utc(2026, 3, 19, 8), count: 5),
          ListingDailyCount(day: DateTime.utc(2026, 3, 18, 8), count: 4),
          ListingDailyCount(day: DateTime.utc(2026, 3, 17, 8), count: 6),
        ],
        now: now,
      );

      expect(data.currentQualifyingStreakDays, 1);
      expect(data.streakQualified, isFalse);
      expect(data.remainingDaysForStreak, 29);
      expect(
        data.listingTargetMilestones.first.status,
        ListingTargetStatus.current,
      );
    });
  });
}
