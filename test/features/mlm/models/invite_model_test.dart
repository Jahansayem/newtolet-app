import 'package:flutter_test/flutter_test.dart';
import 'package:newtolet/core/constants/app_constants.dart';
import 'package:newtolet/features/mlm/models/invite_model.dart';

void main() {
  group('InviteModel.fromJson', () {
    test('parses integer points_awarded values', () {
      final invite = InviteModel.fromJson({
        'id': 'invite-1',
        'inviter_id': 'user-1',
        'invited_email': 'agent@example.com',
        'status': 'completed',
        'points_awarded': 75,
      });

      expect(invite.pointsAwarded, 75);
    });

    test('maps legacy boolean points_awarded values', () {
      final awardedInvite = InviteModel.fromJson({
        'id': 'invite-2',
        'inviter_id': 'user-1',
        'invited_email': 'agent@example.com',
        'status': 'completed',
        'points_awarded': true,
      });
      final pendingInvite = InviteModel.fromJson({
        'id': 'invite-3',
        'inviter_id': 'user-1',
        'invited_email': 'agent@example.com',
        'status': 'pending',
        'points_awarded': false,
      });

      expect(awardedInvite.pointsAwarded, AppConstants.pointsPerInvite);
      expect(pendingInvite.pointsAwarded, 0);
    });
  });
}
