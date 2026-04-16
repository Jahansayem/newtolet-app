import 'package:flutter_test/flutter_test.dart';
import 'package:newtolet/shared/data/bd_locations.dart';

void main() {
  test('BdLocations exposes the full Bangladesh district and upazila set', () {
    final allDistricts = BdLocations.getAllDistricts();
    final allUpazilas = <String>[];

    for (final district in allDistricts) {
      allUpazilas.addAll(BdLocations.getUpazilas(district));
    }

    expect(BdLocations.divisions, hasLength(8));
    expect(allDistricts, hasLength(64));
    expect(allDistricts.toSet(), hasLength(64));
    expect(allUpazilas, hasLength(495));
  });

  test('every district in the bundled dataset has at least one upazila', () {
    for (final district in BdLocations.getAllDistricts()) {
      expect(
        BdLocations.getUpazilas(district),
        isNotEmpty,
        reason: '$district should have at least one upazila',
      );
    }
  });
}
