import 'dart:typed_data';

/// Holds all form state across the multi-step Add Listing flow.
///
/// Each field group corresponds to one step in the stepper.
/// [toSupabaseJson] maps field names to the `properties` table column names.
class ListingFormData {
  const ListingFormData({
    // Step 1 - Category & Type
    this.category,
    this.propertyType,
    this.occupancy,
    // Step 2 - Property Details
    this.totalRooms = 1,
    this.totalBathrooms = 1,
    this.totalKitchen = 1,
    this.balcony = 0,
    this.floorLevel,
    this.roomSizeSqft,
    this.rentAmountBdt,
    this.isRentNegotiable = false,
    this.rentPeriod = 'Monthly',
    // Step 3 - Location
    this.division,
    this.district,
    this.thana,
    this.road,
    this.sector,
    this.housePlot,
    this.contactNumber,
    this.shortDescription,
    this.lat,
    this.lng,
    // Step 4 - Photos & Amenities
    this.photoBytes = const [],
    this.amenities = const [],
    this.availableFrom,
    this.deadline,
  });

  // ---------------------------------------------------------------------------
  // Step 1 - Category & Type
  // ---------------------------------------------------------------------------

  final String? category;
  final String? propertyType;
  final String? occupancy;

  // ---------------------------------------------------------------------------
  // Step 2 - Property Details
  // ---------------------------------------------------------------------------

  final int totalRooms;
  final int totalBathrooms;
  final int totalKitchen;
  final int balcony;
  final String? floorLevel;
  final int? roomSizeSqft;
  final int? rentAmountBdt;
  final bool isRentNegotiable;
  final String rentPeriod;

  // ---------------------------------------------------------------------------
  // Step 3 - Location
  // ---------------------------------------------------------------------------

  /// Stored in the legacy `state_district` column in `properties`.
  final String? division;

  /// Stored in the legacy `area` column in `properties`.
  final String? district;

  /// Stored in the legacy `sub_area` column in `properties`.
  final String? thana;

  final String? road;

  /// Stores the selected sub-area/locality when one is available.
  final String? sector;
  final String? housePlot;
  final String? contactNumber;
  final String? shortDescription;
  final double? lat;
  final double? lng;

  // ---------------------------------------------------------------------------
  // Step 4 - Photos & Amenities
  // ---------------------------------------------------------------------------

  final List<Uint8List> photoBytes;
  final List<String> amenities;
  final DateTime? availableFrom;
  final DateTime? deadline;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Converts form data to a JSON map matching the `properties` table columns.
  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'user_id': userId,
      'category': category,
      'property_type': propertyType,
      'total_rooms': totalRooms,
      'total_bathrooms': totalBathrooms,
      'total_kitchen': totalKitchen,
      'balcony': balcony,
      'floor_level': floorLevel,
      'occupancy': occupancy,
      'room_size_sqft': roomSizeSqft,
      'rent_amount_bdt': rentAmountBdt,
      'is_rent_negotiable': isRentNegotiable,
      'rent_period': rentPeriod,
      'state_district': division,
      'area': district,
      'sub_area': thana,
      'contact_number': contactNumber,
      'short_description': shortDescription,
      'sector': sector,
      'road': road,
      'house_plot': housePlot,
      'lat': lat,
      'lng': lng,
      'available_from': availableFrom?.toIso8601String().split('T').first,
      'deadline': deadline?.toIso8601String().split('T').first,
      'status': 'pending',
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  ListingFormData copyWith({
    String? category,
    String? propertyType,
    String? occupancy,
    int? totalRooms,
    int? totalBathrooms,
    int? totalKitchen,
    int? balcony,
    String? floorLevel,
    int? roomSizeSqft,
    int? rentAmountBdt,
    bool? isRentNegotiable,
    String? rentPeriod,
    String? division,
    String? district,
    String? thana,
    String? road,
    String? sector,
    String? housePlot,
    String? contactNumber,
    String? shortDescription,
    double? lat,
    double? lng,
    List<Uint8List>? photoBytes,
    List<String>? amenities,
    DateTime? availableFrom,
    DateTime? deadline,
    // Use these sentinel flags to allow setting nullable fields to null.
    bool clearDivision = false,
    bool clearDistrict = false,
    bool clearThana = false,
    bool clearSector = false,
    bool clearFloorLevel = false,
    bool clearRentAmountBdt = false,
  }) {
    return ListingFormData(
      category: category ?? this.category,
      propertyType: propertyType ?? this.propertyType,
      occupancy: occupancy ?? this.occupancy,
      totalRooms: totalRooms ?? this.totalRooms,
      totalBathrooms: totalBathrooms ?? this.totalBathrooms,
      totalKitchen: totalKitchen ?? this.totalKitchen,
      balcony: balcony ?? this.balcony,
      floorLevel: clearFloorLevel ? null : (floorLevel ?? this.floorLevel),
      roomSizeSqft: roomSizeSqft ?? this.roomSizeSqft,
      rentAmountBdt: clearRentAmountBdt
          ? null
          : (rentAmountBdt ?? this.rentAmountBdt),
      isRentNegotiable: isRentNegotiable ?? this.isRentNegotiable,
      rentPeriod: rentPeriod ?? this.rentPeriod,
      division: clearDivision ? null : (division ?? this.division),
      district: clearDistrict ? null : (district ?? this.district),
      thana: clearThana ? null : (thana ?? this.thana),
      road: road ?? this.road,
      sector: clearSector ? null : (sector ?? this.sector),
      housePlot: housePlot ?? this.housePlot,
      contactNumber: contactNumber ?? this.contactNumber,
      shortDescription: shortDescription ?? this.shortDescription,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      photoBytes: photoBytes ?? this.photoBytes,
      amenities: amenities ?? this.amenities,
      availableFrom: availableFrom ?? this.availableFrom,
      deadline: deadline ?? this.deadline,
    );
  }
}
