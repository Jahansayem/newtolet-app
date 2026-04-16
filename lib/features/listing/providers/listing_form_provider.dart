import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listing_form_data.dart';

// ---------------------------------------------------------------------------
// Form state wrapper
// ---------------------------------------------------------------------------

/// Immutable state holding the listing form data.
class ListingFormState {
  const ListingFormState({this.formData = const ListingFormData()});

  final ListingFormData formData;

  ListingFormState copyWith({ListingFormData? formData}) {
    return ListingFormState(formData: formData ?? this.formData);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final listingFormProvider =
    StateNotifierProvider.autoDispose<ListingFormNotifier, ListingFormState>(
      (ref) => ListingFormNotifier(),
    );

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ListingFormNotifier extends StateNotifier<ListingFormState> {
  ListingFormNotifier() : super(const ListingFormState());

  void reset() {
    state = const ListingFormState();
  }

  // ---- Step 1 - Category & Type -------------------------------------------

  void setCategory(String category) {
    state = state.copyWith(
      formData: state.formData.copyWith(category: category),
    );
  }

  void setPropertyType(String type) {
    state = state.copyWith(
      formData: state.formData.copyWith(propertyType: type),
    );
  }

  void setOccupancy(String occupancy) {
    state = state.copyWith(
      formData: state.formData.copyWith(occupancy: occupancy),
    );
  }

  // ---- Step 2 - Property Details ------------------------------------------

  void setTotalRooms(int value) {
    state = state.copyWith(
      formData: state.formData.copyWith(totalRooms: value),
    );
  }

  void setTotalBathrooms(int value) {
    state = state.copyWith(
      formData: state.formData.copyWith(totalBathrooms: value),
    );
  }

  void setTotalKitchen(int value) {
    state = state.copyWith(
      formData: state.formData.copyWith(totalKitchen: value),
    );
  }

  void setBalcony(int value) {
    state = state.copyWith(formData: state.formData.copyWith(balcony: value));
  }

  void setFloorLevel(String? value) {
    state = state.copyWith(
      formData: value == null
          ? state.formData.copyWith(clearFloorLevel: true)
          : state.formData.copyWith(floorLevel: value),
    );
  }

  void setRoomSizeSqft(int? value) {
    state = state.copyWith(
      formData: state.formData.copyWith(roomSizeSqft: value),
    );
  }

  void setRentAmountBdt(int? value) {
    state = state.copyWith(
      formData: value == null
          ? state.formData.copyWith(clearRentAmountBdt: true)
          : state.formData.copyWith(rentAmountBdt: value),
    );
  }

  void setRentNegotiable(bool value) {
    state = state.copyWith(
      formData: state.formData.copyWith(isRentNegotiable: value),
    );
  }

  void setRentPeriod(String value) {
    state = state.copyWith(
      formData: state.formData.copyWith(rentPeriod: value),
    );
  }

  // ---- Step 3 - Location --------------------------------------------------

  void setDivision(String? value) {
    // When division changes, reset district, area, and sub-area.
    state = state.copyWith(
      formData: value == null
          ? state.formData.copyWith(
              clearDivision: true,
              clearDistrict: true,
              clearThana: true,
              clearSector: true,
            )
          : state.formData.copyWith(
              division: value,
              clearDistrict: true,
              clearThana: true,
              clearSector: true,
            ),
    );
  }

  void setDistrict(String? value) {
    // When district changes, reset area and sub-area.
    state = state.copyWith(
      formData: value == null
          ? state.formData.copyWith(
              clearDistrict: true,
              clearThana: true,
              clearSector: true,
            )
          : state.formData.copyWith(
              district: value,
              clearThana: true,
              clearSector: true,
            ),
    );
  }

  void setThana(String? value) {
    state = state.copyWith(
      formData: value == null
          ? state.formData.copyWith(clearThana: true, clearSector: true)
          : state.formData.copyWith(thana: value, clearSector: true),
    );
  }

  void setRoad(String value) {
    state = state.copyWith(formData: state.formData.copyWith(road: value));
  }

  void setSector(String? value) {
    state = state.copyWith(
      formData: value == null
          ? state.formData.copyWith(clearSector: true)
          : state.formData.copyWith(sector: value),
    );
  }

  void setHousePlot(String value) {
    state = state.copyWith(formData: state.formData.copyWith(housePlot: value));
  }

  void setContactNumber(String value) {
    state = state.copyWith(
      formData: state.formData.copyWith(contactNumber: value),
    );
  }

  void setShortDescription(String value) {
    state = state.copyWith(
      formData: state.formData.copyWith(shortDescription: value),
    );
  }

  void setLatLng(double lat, double lng) {
    state = state.copyWith(
      formData: state.formData.copyWith(lat: lat, lng: lng),
    );
  }

  // ---- Step 4 - Photos & Amenities ----------------------------------------

  void addPhotoBytes(Uint8List bytes) {
    final current = List<Uint8List>.from(state.formData.photoBytes);
    if (current.length < 10) {
      current.add(bytes);
      state = state.copyWith(
        formData: state.formData.copyWith(photoBytes: current),
      );
    }
  }

  void addPhotoBytesBatch(Iterable<Uint8List> bytesList) {
    final current = List<Uint8List>.from(state.formData.photoBytes);
    for (final bytes in bytesList) {
      if (current.length >= 10) break;
      current.add(bytes);
    }
    state = state.copyWith(
      formData: state.formData.copyWith(photoBytes: current),
    );
  }

  void removePhotoAt(int index) {
    final current = List<Uint8List>.from(state.formData.photoBytes);
    if (index >= 0 && index < current.length) {
      current.removeAt(index);
      state = state.copyWith(
        formData: state.formData.copyWith(photoBytes: current),
      );
    }
  }

  void toggleAmenity(String amenity) {
    final current = List<String>.from(state.formData.amenities);
    if (current.contains(amenity)) {
      current.remove(amenity);
    } else {
      current.add(amenity);
    }
    state = state.copyWith(
      formData: state.formData.copyWith(amenities: current),
    );
  }

  void setAvailableFrom(DateTime? date) {
    state = state.copyWith(
      formData: state.formData.copyWith(availableFrom: date),
    );
  }

  void setDeadline(DateTime? date) {
    state = state.copyWith(formData: state.formData.copyWith(deadline: date));
  }

  // ---- Validation ---------------------------------------------------------

  /// Returns an error message string if the entire form is invalid,
  /// or `null` if everything passes.
  String? validateForm() {
    final fd = state.formData;

    if (fd.category == null || fd.category!.isEmpty) {
      return 'Please select a category';
    }
    if (fd.propertyType == null || fd.propertyType!.isEmpty) {
      return 'Please select a property type';
    }
    if (fd.occupancy == null || fd.occupancy!.isEmpty) {
      return 'Please select an occupancy type';
    }
    if (fd.rentAmountBdt == null || fd.rentAmountBdt! <= 0) {
      return 'Please enter a valid rent amount';
    }
    if (fd.photoBytes.isEmpty) {
      return 'Please add at least one photo';
    }
    if (fd.division == null || fd.division!.isEmpty) {
      return 'Please select a division';
    }
    if (fd.district == null || fd.district!.isEmpty) {
      return 'Please select a district';
    }
    if (fd.thana == null || fd.thana!.trim().isEmpty) {
      return 'Please select an area / thana';
    }
    if (fd.contactNumber == null || fd.contactNumber!.isEmpty) {
      return 'Please enter a contact number';
    }

    return null;
  }
}
