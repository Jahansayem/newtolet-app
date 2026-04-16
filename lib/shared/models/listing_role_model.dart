class ListingRoleModel {
  const ListingRoleModel({
    required this.id,
    required this.roleKey,
    required this.displayName,
    required this.pointsPerListing,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String roleKey;
  final String displayName;
  final int pointsPerListing;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ListingRoleModel.fromJson(Map<String, dynamic> json) {
    return ListingRoleModel(
      id: json['id'] as String,
      roleKey: json['role_key'] as String,
      displayName: json['display_name'] as String,
      pointsPerListing: (json['points_per_listing'] as num).toInt(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
