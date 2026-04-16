import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newtolet/features/home/models/property_model.dart';
import 'package:newtolet/features/listing/presentation/screens/my_listings_screen.dart';
import 'package:newtolet/features/listing/providers/my_listings_provider.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<PropertyModel> listings,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myListingsProvider.overrideWith(
            () => _FakeMyListingsNotifier(listings),
          ),
        ],
        child: const MaterialApp(home: MyListingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows Bangladesh daily report above listing content', (
    tester,
  ) async {
    final now = _nowDhaka();

    await pumpScreen(
      tester,
      listings: [
        _listing(id: '1', category: 'Flat', createdAt: now),
        _listing(
          id: '2',
          category: 'Sublet',
          createdAt: now.subtract(const Duration(hours: 18)),
        ),
      ],
    );

    expect(find.text('Bangladesh Listing Report'), findsOneWidget);
    expect(find.text('Submitted Today'), findsOneWidget);
    expect(find.text('Yesterday Report'), findsOneWidget);
    expect(find.text('Bangladesh time (UTC+6)'), findsOneWidget);

    final reportTitleTop = tester
        .getTopLeft(find.text('Bangladesh Listing Report'))
        .dy;
    final listingTitleTop = tester.getTopLeft(find.text('Flat')).dy;
    expect(reportTitleTop, lessThan(listingTitleTop));
  });

  testWidgets('calculates today and yesterday counts in Bangladesh time', (
    tester,
  ) async {
    final now = _nowDhaka();

    await pumpScreen(
      tester,
      listings: [
        _listing(id: '1', category: 'Flat', createdAt: now),
        _listing(
          id: '2',
          category: 'Room',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        _listing(
          id: '3',
          category: 'Office',
          createdAt: now.subtract(const Duration(hours: 20)),
        ),
      ],
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows zero-count report when there are no listings', (
    tester,
  ) async {
    await pumpScreen(tester, listings: const []);

    expect(find.text('Bangladesh Listing Report'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('No Listings Yet'), findsOneWidget);
  });
}

class _FakeMyListingsNotifier extends MyListingsNotifier {
  _FakeMyListingsNotifier(this._listings);

  final List<PropertyModel> _listings;

  @override
  Future<List<PropertyModel>> build() async => _listings;

  @override
  Future<void> refresh() async {
    state = AsyncData(_listings);
  }

  @override
  Future<void> deleteListing(String propertyId) async {}
}

PropertyModel _listing({
  required String id,
  required String category,
  required DateTime createdAt,
}) {
  return PropertyModel(
    id: id,
    userId: 'user-1',
    category: category,
    createdAt: createdAt,
  );
}

DateTime _nowDhaka() => DateTime.now().toUtc().add(const Duration(hours: 6));
