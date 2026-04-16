import 'package:flutter_test/flutter_test.dart';
import 'package:newtolet/features/home/providers/property_filter_provider.dart';

void main() {
  test('setting district clears any previously selected upazila', () {
    final notifier = PropertyFilterNotifier();

    notifier.setDistrict('Dhaka');
    notifier.setUpazila('Savar');
    expect(notifier.state.upazila, 'Savar');

    notifier.setDistrict('Gazipur');

    expect(notifier.state.district, 'Gazipur');
    expect(notifier.state.upazila, isNull);
  });

  test('clearAll removes district and upazila filters', () {
    final notifier = PropertyFilterNotifier();

    notifier.setDistrict('Dhaka');
    notifier.setUpazila('Keraniganj');
    expect(notifier.state.hasActiveFilters, isTrue);

    notifier.clearAll();

    expect(notifier.state.district, isNull);
    expect(notifier.state.upazila, isNull);
    expect(notifier.state.hasActiveFilters, isFalse);
  });
}
