/// Data model mapping to the `users` table in Supabase.
///
/// Includes all columns required by the active rental, MLM, and earnings flow.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.name,
    this.verified = false,
    this.isActive = true,
    this.role = 'agent',
    this.sponsorId,
    this.placementParentId,
    this.referralCode,
    this.starLevel = 0,
    this.ppv = 0,
    this.balanceUsd = 0.0,
    this.activityStatus = 'low_active',
    this.profileImageUrl,
    this.division,
    this.district,
    this.bkashNumber,
    this.nagadNumber,
    this.lastActiveAt,
    this.firstListingCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  final String id;
  final String email;
  final String? phone;
  final String? name;
  final bool verified;
  final bool isActive;
  final String role;
  final String? sponsorId;
  final String? placementParentId;
  final String? referralCode;
  final int starLevel;
  final int ppv;
  final double balanceUsd;
  final String activityStatus;
  final String? profileImageUrl;
  final String? division;
  final String? district;
  final String? bkashNumber;
  final String? nagadNumber;
  final DateTime? lastActiveAt;
  final bool firstListingCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ---------------------------------------------------------------------------
  // JSON serialisation
  // ---------------------------------------------------------------------------

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      name: json['name'] as String?,
      verified: json['verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      role: json['role'] as String? ?? 'agent',
      sponsorId: json['sponsor_id'] as String?,
      placementParentId: json['placement_parent_id'] as String?,
      referralCode: json['referral_code'] as String?,
      starLevel: (json['star_level'] as num?)?.toInt() ?? 0,
      ppv: (json['ppv'] as num?)?.toInt() ?? 0,
      balanceUsd: (json['balance_usd'] as num?)?.toDouble() ?? 0.0,
      activityStatus: json['activity_status'] as String? ?? 'low_active',
      profileImageUrl: json['profile_image_url'] as String?,
      division: json['division'] as String?,
      district: json['district'] as String?,
      bkashNumber: json['bkash_number'] as String?,
      nagadNumber: json['nagad_number'] as String?,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      firstListingCompleted: json['first_listing_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'verified': verified,
      'is_active': isActive,
      'role': role,
      'sponsor_id': sponsorId,
      'placement_parent_id': placementParentId,
      'referral_code': referralCode,
      'star_level': starLevel,
      'ppv': ppv,
      'balance_usd': balanceUsd,
      'activity_status': activityStatus,
      'profile_image_url': profileImageUrl,
      'division': division,
      'district': district,
      'bkash_number': bkashNumber,
      'nagad_number': nagadNumber,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'first_listing_completed': firstListingCompleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? name,
    bool? verified,
    bool? isActive,
    String? role,
    String? sponsorId,
    String? placementParentId,
    String? referralCode,
    int? starLevel,
    int? ppv,
    double? balanceUsd,
    String? activityStatus,
    String? profileImageUrl,
    String? division,
    String? district,
    String? bkashNumber,
    String? nagadNumber,
    DateTime? lastActiveAt,
    bool? firstListingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      verified: verified ?? this.verified,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      sponsorId: sponsorId ?? this.sponsorId,
      placementParentId: placementParentId ?? this.placementParentId,
      referralCode: referralCode ?? this.referralCode,
      starLevel: starLevel ?? this.starLevel,
      ppv: ppv ?? this.ppv,
      balanceUsd: balanceUsd ?? this.balanceUsd,
      activityStatus: activityStatus ?? this.activityStatus,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      division: division ?? this.division,
      district: district ?? this.district,
      bkashNumber: bkashNumber ?? this.bkashNumber,
      nagadNumber: nagadNumber ?? this.nagadNumber,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      firstListingCompleted:
          firstListingCompleted ?? this.firstListingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & toString
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserModel(id: $id, email: $email, name: $name)';
}
