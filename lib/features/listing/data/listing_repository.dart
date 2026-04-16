import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../features/home/models/property_model.dart';
import '../../../shared/providers/supabase_provider.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ListingRepository(client);
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

/// Data layer for creating, reading, and deleting property listings.
class ListingRepository {
  ListingRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();
  static const _imageBucket = 'property-images';

  // ---------------------------------------------------------------------------
  // Create listing
  // ---------------------------------------------------------------------------

  /// Inserts a property row into the `properties` table.
  ///
  /// Returns the auto-generated property `id`.
  Future<String> createListing(Map<String, dynamic> data) async {
    final response = await _client
        .from('properties')
        .insert(data)
        .select('id')
        .single();
    return response['id'] as String;
  }

  // ---------------------------------------------------------------------------
  // Upload images
  // ---------------------------------------------------------------------------

  /// Compresses each image from [photoBytes], uploads to Supabase Storage
  /// bucket `property-images`, then inserts metadata rows into
  /// `property_images`. The first image is marked as the thumbnail.
  Future<void> uploadImages(
    String propertyId,
    List<Uint8List> photoBytes,
  ) async {
    if (photoBytes.isEmpty) return;

    final storage = _client.storage.from(_imageBucket);
    final List<Map<String, dynamic>> imageRows = [];

    for (int i = 0; i < photoBytes.length; i++) {
      final fileId = _uuid.v4();
      final storagePath = '$propertyId/$fileId.jpg';

      // Compress the image to a maximum of ~500 KB.
      final Uint8List? compressedBytes = await normalizeImageBytes(
        photoBytes[i],
      );
      if (compressedBytes == null) continue;

      // Upload to Supabase Storage.
      try {
        await _uploadBinaryWithRetry(
          storage: storage,
          storagePath: storagePath,
          bytes: compressedBytes,
        );
      } catch (error) {
        throw StateError(
          'Failed to upload photo ${i + 1}. '
          'Check your network connection and try again. ($error)',
        );
      }

      // Get the public URL for the uploaded image.
      final publicUrl = storage.getPublicUrl(storagePath);

      imageRows.add({
        'property_id': propertyId,
        'image_url': publicUrl,
        'is_thumbnail': i == 0,
        'display_order': i,
      });
    }

    if (imageRows.isEmpty) {
      throw StateError(
        'No selected photos could be prepared for upload. Please choose a different image and try again.',
      );
    }

    if (imageRows.isNotEmpty) {
      await _client.from('property_images').insert(imageRows);
    }
  }

  Future<void> _uploadBinaryWithRetry({
    required StorageFileApi storage,
    required String storagePath,
    required Uint8List bytes,
  }) async {
    const retryDelays = [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 2),
    ];

    Object? lastError;
    for (final delay in retryDelays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      try {
        await storage.uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
        return;
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? StateError('Unknown upload failure.');
  }

  /// Compresses image [bytes] to JPEG, targeting max ~500 KB.
  static Future<Uint8List?> normalizeImageBytes(Uint8List bytes) async {
    final originalSize = bytes.lengthInBytes;

    // If already under 500 KB, light compression only.
    int quality = 85;
    if (originalSize > 2 * 1024 * 1024) {
      quality = 50;
    } else if (originalSize > 1024 * 1024) {
      quality = 60;
    } else if (originalSize > 500 * 1024) {
      quality = 70;
    }

    Uint8List result;
    try {
      result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1200,
        minHeight: 1200,
        quality: quality,
        format: CompressFormat.jpeg,
      );
    } catch (_) {
      return null;
    }

    if (result.lengthInBytes > 500 * 1024) {
      try {
        result = await FlutterImageCompress.compressWithList(
          result,
          minWidth: 1024,
          minHeight: 1024,
          quality: 40,
          format: CompressFormat.jpeg,
        );
      } catch (_) {
        return Uint8List.fromList(result);
      }
    }

    return Uint8List.fromList(result);
  }

  // ---------------------------------------------------------------------------
  // Amenities
  // ---------------------------------------------------------------------------

  /// Batch-inserts amenity rows into `property_amenities`.
  Future<void> addAmenities(String propertyId, List<String> amenities) async {
    if (amenities.isEmpty) return;

    final rows = amenities
        .map((a) => {'property_id': propertyId, 'amenity_type': a})
        .toList();

    await _client.from('property_amenities').insert(rows);
  }

  // ---------------------------------------------------------------------------
  // Read user's listings
  // ---------------------------------------------------------------------------

  /// Fetches all properties belonging to [userId], including joined images
  /// and amenities, ordered by creation date descending.
  Future<List<PropertyModel>> getMyListings(String userId) async {
    final response = await _client
        .from('properties')
        .select('*, property_images(*), property_amenities(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data
        .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Delete listing
  // ---------------------------------------------------------------------------

  /// Deletes a property and its associated images and amenities.
  ///
  /// Also removes image files from Supabase Storage.
  Future<void> deleteListing(String propertyId) async {
    // Fetch existing image paths to remove from storage.
    final images = await _client
        .from('property_images')
        .select('image_url')
        .eq('property_id', propertyId);

    // Delete storage files.
    final storage = _client.storage.from(_imageBucket);
    for (final img in (images as List<dynamic>)) {
      final url = (img as Map<String, dynamic>)['image_url'] as String?;
      if (url != null && url.contains('$_imageBucket/')) {
        // Extract the path after the bucket name.
        final parts = url.split('$_imageBucket/');
        if (parts.length > 1) {
          try {
            await storage.remove([parts.last]);
          } catch (_) {
            // Best-effort cleanup; continue even if a file is already gone.
          }
        }
      }
    }

    // Delete child rows first, then the property.
    await _client
        .from('property_images')
        .delete()
        .eq('property_id', propertyId);
    await _client
        .from('property_amenities')
        .delete()
        .eq('property_id', propertyId);
    await _client.from('properties').delete().eq('id', propertyId);
  }
}
