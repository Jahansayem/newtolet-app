/// Data model mapping to the `properties` table in Supabase, including
/// joined data from `property_images` and `property_amenities`.
class PropertyModel {
  const PropertyModel({
    required this.id,
    required this.userId,
    this.category,
    this.propertyType,
    this.totalRooms,
    this.totalBathrooms,
    this.balcony,
    this.floorLevel,
    this.occupancy,
    this.roomSizeSqft,
    this.rentAmountBdt,
    this.isRentNegotiable = false,
    this.rentPeriod,
    this.stateDistrict,
    this.area,
    this.contactNumber,
    this.shortDescription,
    this.sector,
    this.road,
    this.housePlot,
    this.lat,
    this.lng,
    this.availableFrom,
    this.deadline,
    this.status,
    this.views = 0,
    this.createdAt,
    this.updatedAt,
    this.subArea,
    this.totalKitchen,
    this.imageUrls = const [],
    this.thumbnailUrl,
    this.amenities = const [],
    this.isFavorited = false,
  });

  // ---------------------------------------------------------------------------
  // Fields from properties table
  // ---------------------------------------------------------------------------

  final String id;
  final String userId;
  final String? category;
  final String? propertyType;
  final int? totalRooms;
  final int? totalBathrooms;
  final int? balcony;
  final String? floorLevel;
  final String? occupancy;
  final int? roomSizeSqft;
  final int? rentAmountBdt;
  final bool isRentNegotiable;
  final String? rentPeriod;
  final String? stateDistrict;
  final String? area;
  final String? contactNumber;
  final String? shortDescription;
  final String? sector;
  final String? road;
  final String? housePlot;
  final double? lat;
  final double? lng;
  final DateTime? availableFrom;
  final DateTime? deadline;
  final String? status;
  final int views;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? subArea;
  final int? totalKitchen;

  // ---------------------------------------------------------------------------
  // Joined / computed fields
  // ---------------------------------------------------------------------------

  /// All image URLs from `property_images`, ordered by `display_order`.
  final List<String> imageUrls;

  /// The thumbnail image URL (where `is_thumbnail = true`), falling back to
  /// the first image in [imageUrls].
  final String? thumbnailUrl;

  /// Amenity type strings from `property_amenities`.
  final List<String> amenities;

  /// Whether the current user has favorited this property.
  final bool isFavorited;

  // ---------------------------------------------------------------------------
  // Computed helpers
  // ---------------------------------------------------------------------------

  /// Human-readable location string combining available fields.
  String get locationText {
    final parts = <String>[];
    if (area != null && area!.isNotEmpty) parts.add(area!);
    if (subArea != null && subArea!.isNotEmpty) parts.add(subArea!);
    if (stateDistrict != null && stateDistrict!.isNotEmpty) {
      parts.add(stateDistrict!);
    }
    return parts.join(', ');
  }

  /// Short location for card display.
  String get shortLocation {
    if (area != null && area!.isNotEmpty) {
      if (stateDistrict != null && stateDistrict!.isNotEmpty) {
        return '$area, $stateDistrict';
      }
      return area!;
    }
    return stateDistrict ?? '';
  }

  // ---------------------------------------------------------------------------
  // JSON serialisation
  // ---------------------------------------------------------------------------

  /// Creates a [PropertyModel] from a Supabase response that includes nested
  /// `property_images` and `property_amenities` via a select join:
  /// ```
  /// select('*, property_images(*), property_amenities(*)')
  /// ```
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // --- Parse images ---
    final rawImages = json['property_images'] as List<dynamic>? ?? [];
    // Sort by display_order ascending.
    final sortedImages =
        List<Map<String, dynamic>>.from(
          rawImages.map((e) => e as Map<String, dynamic>),
        )..sort((a, b) {
          final orderA = (a['display_order'] as num?)?.toInt() ?? 999;
          final orderB = (b['display_order'] as num?)?.toInt() ?? 999;
          return orderA.compareTo(orderB);
        });

    final imageUrls = sortedImages
        .map((img) => img['image_url'] as String?)
        .where((url) => url != null && url.isNotEmpty)
        .cast<String>()
        .toList();

    // Find the designated thumbnail, falling back to the first image.
    String? thumbnailUrl;
    for (final img in sortedImages) {
      if (img['is_thumbnail'] == true) {
        thumbnailUrl = img['image_url'] as String?;
        break;
      }
    }
    thumbnailUrl ??= imageUrls.isNotEmpty ? imageUrls.first : null;

    // --- Parse amenities ---
    final rawAmenities = json['property_amenities'] as List<dynamic>? ?? [];
    final amenities = rawAmenities
        .map((a) => (a as Map<String, dynamic>)['amenity_type'] as String?)
        .where((t) => t != null && t.isNotEmpty)
        .cast<String>()
        .toList();

    return PropertyModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String?,
      propertyType: json['property_type'] as String?,
      totalRooms: (json['total_rooms'] as num?)?.toInt(),
      totalBathrooms: (json['total_bathrooms'] as num?)?.toInt(),
      balcony: (json['balcony'] as num?)?.toInt(),
      floorLevel: json['floor_level'] as String?,
      occupancy: json['occupancy'] as String?,
      roomSizeSqft: (json['room_size_sqft'] as num?)?.toInt(),
      rentAmountBdt: (json['rent_amount_bdt'] as num?)?.toInt(),
      isRentNegotiable: json['is_rent_negotiable'] as bool? ?? false,
      rentPeriod: json['rent_period'] as String?,
      stateDistrict: json['state_district'] as String?,
      area: json['area'] as String?,
      contactNumber: json['contact_number'] as String?,
      shortDescription: json['short_description'] as String?,
      sector: json['sector'] as String?,
      road: json['road'] as String?,
      housePlot: json['house_plot'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      availableFrom: json['available_from'] != null
          ? DateTime.tryParse(json['available_from'] as String)
          : null,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      status: json['status'] as String?,
      views: (json['views'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      subArea: json['sub_area'] as String?,
      totalKitchen: (json['total_kitchen'] as num?)?.toInt(),
      imageUrls: imageUrls,
      thumbnailUrl: thumbnailUrl,
      amenities: amenities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'property_type': propertyType,
      'total_rooms': totalRooms,
      'total_bathrooms': totalBathrooms,
      'balcony': balcony,
      'floor_level': floorLevel,
      'occupancy': occupancy,
      'room_size_sqft': roomSizeSqft,
      'rent_amount_bdt': rentAmountBdt,
      'is_rent_negotiable': isRentNegotiable,
      'rent_period': rentPeriod,
      'state_district': stateDistrict,
      'area': area,
      'contact_number': contactNumber,
      'short_description': shortDescription,
      'sector': sector,
      'road': road,
      'house_plot': housePlot,
      'lat': lat,
      'lng': lng,
      'available_from': availableFrom?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'views': views,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sub_area': subArea,
      'total_kitchen': totalKitchen,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  PropertyModel copyWith({
    String? id,
    String? userId,
    String? category,
    String? propertyType,
    int? totalRooms,
    int? totalBathrooms,
    int? balcony,
    String? floorLevel,
    String? occupancy,
    int? roomSizeSqft,
    int? rentAmountBdt,
    bool? isRentNegotiable,
    String? rentPeriod,
    String? stateDistrict,
    String? area,
    String? contactNumber,
    String? shortDescription,
    String? sector,
    String? road,
    String? housePlot,
    double? lat,
    double? lng,
    DateTime? availableFrom,
    DateTime? deadline,
    String? status,
    int? views,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? subArea,
    int? totalKitchen,
    List<String>? imageUrls,
    String? thumbnailUrl,
    List<String>? amenities,
    bool? isFavorited,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      propertyType: propertyType ?? this.propertyType,
      totalRooms: totalRooms ?? this.totalRooms,
      totalBathrooms: totalBathrooms ?? this.totalBathrooms,
      balcony: balcony ?? this.balcony,
      floorLevel: floorLevel ?? this.floorLevel,
      occupancy: occupancy ?? this.occupancy,
      roomSizeSqft: roomSizeSqft ?? this.roomSizeSqft,
      rentAmountBdt: rentAmountBdt ?? this.rentAmountBdt,
      isRentNegotiable: isRentNegotiable ?? this.isRentNegotiable,
      rentPeriod: rentPeriod ?? this.rentPeriod,
      stateDistrict: stateDistrict ?? this.stateDistrict,
      area: area ?? this.area,
      contactNumber: contactNumber ?? this.contactNumber,
      shortDescription: shortDescription ?? this.shortDescription,
      sector: sector ?? this.sector,
      road: road ?? this.road,
      housePlot: housePlot ?? this.housePlot,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      availableFrom: availableFrom ?? this.availableFrom,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subArea: subArea ?? this.subArea,
      totalKitchen: totalKitchen ?? this.totalKitchen,
      imageUrls: imageUrls ?? this.imageUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      amenities: amenities ?? this.amenities,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & toString
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PropertyModel(id: $id, category: $category, rent: $rentAmountBdt)';
}
