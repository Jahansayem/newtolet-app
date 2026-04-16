import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'listing_step2_location_submit.dart';

/// Single-page form screen for adding a new property listing.
class AddListingScreen extends StatelessWidget {
  const AddListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Listing',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: const ListingStep2LocationSubmit(),
    );
  }
}
