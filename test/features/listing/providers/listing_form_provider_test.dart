import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:newtolet/features/listing/providers/listing_form_provider.dart';

void main() {
  group('ListingFormNotifier', () {
    test('stores and removes photo bytes without filesystem paths', () {
      final notifier = ListingFormNotifier();
      final firstPhoto = Uint8List.fromList([1, 2, 3]);
      final secondPhoto = Uint8List.fromList([4, 5, 6]);

      notifier.addPhotoBytes(firstPhoto);
      notifier.addPhotoBytes(secondPhoto);

      expect(notifier.state.formData.photoBytes, hasLength(2));
      expect(notifier.state.formData.photoBytes.first, same(firstPhoto));

      notifier.removePhotoAt(0);

      expect(notifier.state.formData.photoBytes, hasLength(1));
      expect(notifier.state.formData.photoBytes.single, same(secondPhoto));
    });

    test('limits stored photos to 10 items', () {
      final notifier = ListingFormNotifier();
      final photos = List.generate(
        12,
        (index) => Uint8List.fromList([index, index + 1]),
      );

      notifier.addPhotoBytesBatch(photos);

      expect(notifier.state.formData.photoBytes, hasLength(10));
    });

    test(
      'validation passes when required fields and photo bytes are present',
      () {
        final notifier = ListingFormNotifier();

        notifier
          ..setCategory('Family')
          ..setPropertyType('Flat')
          ..setOccupancy('Family')
          ..setRentAmountBdt(12000)
          ..setDivision('Dhaka')
          ..setDistrict('Dhaka')
          ..setThana('Mirpur')
          ..setContactNumber('01700000000')
          ..addPhotoBytes(Uint8List.fromList([1, 2, 3]));

        expect(notifier.validateForm(), isNull);
      },
    );
  });
}
