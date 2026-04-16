import '../../../core/constants/app_constants.dart';

/// Represents a row from the `invites` table.
class InviteModel {
  const InviteModel({
    required this.id,
    required this.inviterId,
    required this.invitedEmail,
    this.invitedUserId,
    required this.status,
    this.pointsAwarded = 0,
    this.createdAt,
  });

  final String id;
  final String inviterId;
  final String invitedEmail;
  final String? invitedUserId;
  final String status; // 'pending' | 'registered' | 'completed'
  final int pointsAwarded;
  final DateTime? createdAt;

  /// Human-readable label for the status.
  String get statusLabel {
    switch (status) {
      case 'registered':
        return 'Registered';
      case 'completed':
        return 'Completed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      id: json['id'] as String,
      inviterId: json['inviter_id'] as String,
      invitedEmail: json['invited_email'] as String,
      invitedUserId: json['invited_user_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      pointsAwarded: _parsePointsAwarded(json['points_awarded']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static int _parsePointsAwarded(dynamic rawValue) {
    if (rawValue is num) return rawValue.toInt();
    if (rawValue is bool) {
      return rawValue ? AppConstants.pointsPerInvite : 0;
    }
    if (rawValue is String) return int.tryParse(rawValue) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InviteModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'InviteModel(id: $id, email: $invitedEmail, status: $status)';
}

/// Aggregated invite statistics.
class InviteStats {
  const InviteStats({
    required this.totalInvites,
    required this.registeredCount,
    required this.completedCount,
  });

  final int totalInvites;
  final int registeredCount;
  final int completedCount;

  int get pendingCount => totalInvites - registeredCount - completedCount;
}
