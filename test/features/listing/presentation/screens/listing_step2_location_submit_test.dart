import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:newtolet/features/listing/presentation/screens/listing_step2_location_submit.dart';
import 'package:newtolet/features/listing/providers/listing_form_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpStep2(
    WidgetTester tester, {
    required Size size,
    double textScale = 1,
    double bottomInset = 0,
    ProviderContainer? container,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.viewInsets = FakeViewPadding(bottom: bottomInset);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      container?.dispose();
    });

    final scope = container == null
        ? ProviderScope(
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData.fromView(
                  tester.view,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: const Scaffold(body: ListingStep2LocationSubmit()),
              ),
            ),
          )
        : UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData.fromView(
                  tester.view,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: const Scaffold(body: ListingStep2LocationSubmit()),
              ),
            ),
          );

    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();
  }

  testWidgets('shows current submission controls and headings', (tester) async {
    await pumpStep2(tester, size: const Size(900, 1400));

    expect(find.text('Visual Gallery'), findsOneWidget);
    expect(find.text('Location Details'), findsOneWidget);
    expect(find.text('Complete Listing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders thumbnail preview from in-memory photo bytes', (
    tester,
  ) async {
    final container = ProviderContainer();
    container
        .read(listingFormProvider.notifier)
        .addPhotoBytes(Uint8List.fromList([1, 2, 3, 4]));

    await pumpStep2(tester, size: const Size(900, 1400), container: container);

    expect(find.text('Thumbnail'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps contact number above sticky footer on small screens', (
    tester,
  ) async {
    await pumpStep2(tester, size: const Size(360, 640), bottomInset: 280);

    final contactField = find.byKey(
      const ValueKey('listing-step2-contact-field'),
    );
    final stickyFooter = find.byKey(
      const ValueKey('listing-step2-sticky-footer'),
    );

    expect(contactField, findsOneWidget);
    expect(stickyFooter, findsOneWidget);

    await tester.showKeyboard(contactField);
    await tester.pumpAndSettle();

    final contactRect = tester.getRect(contactField);
    final footerRect = tester.getRect(stickyFooter);

    expect(contactRect.bottom, lessThan(footerRect.top));
    expect(tester.takeException(), isNull);
  });
}
