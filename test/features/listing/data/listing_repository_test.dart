import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:newtolet/features/listing/data/listing_repository.dart';

void main() {
  group('ListingRepository.normalizeImageBytes', () {
    test('returns null for invalid image data', () async {
      final normalized = await ListingRepository.normalizeImageBytes(
        Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(normalized, isNull);
    });
  });
}
