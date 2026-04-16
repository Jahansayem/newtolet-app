import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/data/bd_locations.dart';
import '../../../../shared/data/thetolet_locations.dart';
import '../../../../shared/providers/current_user_provider.dart';
import '../../data/listing_repository.dart';
import '../../providers/listing_form_provider.dart';
import '../../providers/my_listings_provider.dart';
import 'listing_step1_category.dart';

/// Single-page Add Listing body.
class ListingStep2LocationSubmit extends ConsumerStatefulWidget {
  const ListingStep2LocationSubmit({super.key});

  @override
  ConsumerState<ListingStep2LocationSubmit> createState() =>
      _ListingStep2LocationSubmitState();
}

class _ListingStep2LocationSubmitState
    extends ConsumerState<ListingStep2LocationSubmit>
    with WidgetsBindingObserver {
  final _picker = ImagePicker();

  late final TextEditingController _roadController;
  late final TextEditingController _housePlotController;
  late final TextEditingController _contactController;
  late final TextEditingController _descriptionController;
  late final FocusNode _roadFocusNode;
  late final FocusNode _housePlotFocusNode;
  late final FocusNode _contactFocusNode;
  late final FocusNode _descriptionFocusNode;

  final _roadFieldKey = GlobalKey();
  final _housePlotFieldKey = GlobalKey();
  final _contactFieldKey = GlobalKey();
  final _descriptionFieldKey = GlobalKey();
  final _stickyFooterContextKey = GlobalKey();
  final _stickyFooterKey = const ValueKey('listing-step2-sticky-footer');

  bool _isImportingPhotos = false;
  bool _isSubmitting = false;

  static const _amenityOptions = [
    _AmenityItem('Gas', Icons.local_fire_department),
    _AmenityItem('Water', Icons.water_drop),
    _AmenityItem('Electricity', Icons.bolt),
    _AmenityItem('Lift', Icons.elevator),
    _AmenityItem('Garage', Icons.garage),
    _AmenityItem('Security', Icons.security),
    _AmenityItem('Furnished', Icons.chair),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final fd = ref.read(listingFormProvider).formData;
    _roadController = TextEditingController(text: fd.road ?? '');
    _housePlotController = TextEditingController(text: fd.housePlot ?? '');
    _contactController = TextEditingController(text: fd.contactNumber ?? '');
    _descriptionController = TextEditingController(
      text: fd.shortDescription ?? '',
    );
    _roadFocusNode = FocusNode()..addListener(_handleTrackedFieldFocusChange);
    _housePlotFocusNode = FocusNode()
      ..addListener(_handleTrackedFieldFocusChange);
    _contactFocusNode = FocusNode()
      ..addListener(_handleTrackedFieldFocusChange);
    _descriptionFocusNode = FocusNode()
      ..addListener(_handleTrackedFieldFocusChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _roadFocusNode
      ..removeListener(_handleTrackedFieldFocusChange)
      ..dispose();
    _housePlotFocusNode
      ..removeListener(_handleTrackedFieldFocusChange)
      ..dispose();
    _contactFocusNode
      ..removeListener(_handleTrackedFieldFocusChange)
      ..dispose();
    _descriptionFocusNode
      ..removeListener(_handleTrackedFieldFocusChange)
      ..dispose();
    _roadController.dispose();
    _housePlotController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _scheduleEnsureFocusedFieldVisible();
  }

  void _handleTrackedFieldFocusChange() {
    _scheduleEnsureFocusedFieldVisible();
  }

  void _scheduleEnsureFocusedFieldVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureFocusedFieldVisible();
    });
  }

  Future<void> _ensureFocusedFieldVisible() async {
    final focusedContext = switch (FocusManager.instance.primaryFocus) {
      final FocusNode node when identical(node, _roadFocusNode) =>
        _roadFieldKey.currentContext,
      final FocusNode node when identical(node, _housePlotFocusNode) =>
        _housePlotFieldKey.currentContext,
      final FocusNode node when identical(node, _contactFocusNode) =>
        _contactFieldKey.currentContext,
      final FocusNode node when identical(node, _descriptionFocusNode) =>
        _descriptionFieldKey.currentContext,
      _ => null,
    };

    if (focusedContext == null) return;

    await Scrollable.ensureVisible(
      focusedContext,
      alignment: 0,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );

    final scrollableState = Scrollable.maybeOf(focusedContext);
    final footerContext = _stickyFooterContextKey.currentContext;
    if (scrollableState == null || footerContext == null) return;

    final focusedRenderObject = focusedContext.findRenderObject();
    final footerRenderObject = footerContext.findRenderObject();
    if (focusedRenderObject is! RenderBox || footerRenderObject is! RenderBox) {
      return;
    }

    final focusedBottom = focusedRenderObject
        .localToGlobal(Offset(0, focusedRenderObject.size.height))
        .dy;
    final footerTop = footerRenderObject.localToGlobal(Offset.zero).dy;
    const clearance = 12.0;
    final overlap = focusedBottom - (footerTop - clearance);
    if (overlap <= 0) return;

    final position = scrollableState.position;
    final targetPixels = (position.pixels + overlap).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (targetPixels == position.pixels) return;

    await position.animateTo(
      targetPixels,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final notifier = ref.read(listingFormProvider.notifier);
    final currentCount = ref
        .read(listingFormProvider)
        .formData
        .photoBytes
        .length;
    if (currentCount >= 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 photos allowed.')),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles;
      if (source == ImageSource.gallery) {
        pickedFiles = await _picker.pickMultiImage(
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } else {
        final picked = await _picker.pickImage(
          source: source,
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        pickedFiles = picked == null ? const [] : [picked];
      }

      if (pickedFiles.isEmpty) return;

      if (mounted) {
        setState(() => _isImportingPhotos = true);
      }

      final remaining = 10 - currentCount;
      final importedBytes = <Uint8List>[];
      for (final picked in pickedFiles.take(remaining)) {
        final bytes = await _prepareSelectedPhoto(picked);
        if (bytes != null) {
          importedBytes.add(bytes);
        }
      }

      if (importedBytes.isEmpty) {
        throw StateError(
          'Selected photos could not be prepared. Please choose a different image.',
        );
      }

      notifier.addPhotoBytesBatch(importedBytes);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to prepare selected photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isImportingPhotos = false);
      }
    }
  }

  Future<Uint8List?> _prepareSelectedPhoto(XFile file) async {
    final originalBytes = await file.readAsBytes();
    final normalizedBytes = await ListingRepository.normalizeImageBytes(
      Uint8List.fromList(originalBytes),
    );
    if (normalizedBytes != null) return normalizedBytes;

    try {
      final fallback = await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: 85,
        format: CompressFormat.jpeg,
      );
      return Uint8List.fromList(fallback);
    } catch (_) {
      return null;
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatSubmissionError(Object error) {
    final message = error.toString();
    final normalized = message.toLowerCase();

    if (normalized.contains('connection reset by peer')) {
      return 'Image upload was interrupted by the network. Please try again on a stable connection.';
    }
    if (normalized.contains('selected photos could not be prepared')) {
      return 'Selected photos are no longer available or could not be processed. Please reselect them and try again.';
    }
    if (normalized.contains('property-images')) {
      return 'Listing image storage is not configured correctly on Supabase.';
    }

    final missingListingTable =
        normalized.contains('relation "properties" does not exist') ||
        normalized.contains('relation "property_images" does not exist') ||
        normalized.contains('relation "property_amenities" does not exist') ||
        normalized.contains("table 'properties'") ||
        normalized.contains("table 'property_images'") ||
        normalized.contains("table 'property_amenities'");

    if (missingListingTable) {
      return 'Listing tables are missing or not configured correctly on Supabase.';
    }

    final listingDataError =
        normalized.contains('violates not-null constraint') ||
        normalized.contains('null value in column') ||
        normalized.contains('violates foreign key constraint') ||
        normalized.contains('violates unique constraint') ||
        normalized.contains('invalid input syntax') ||
        normalized.contains('new row for relation') ||
        normalized.contains('property_images') ||
        normalized.contains('property_amenities') ||
        normalized.contains('properties');

    if (listingDataError) {
      return 'Listing data is invalid or incomplete. Please check rent, location, photos, and required fields.';
    }

    return message;
  }

  Future<void> _submit() async {
    final notifier = ref.read(listingFormProvider.notifier);
    final validationError = notifier.validateForm();
    if (validationError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit a listing.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? propertyId;
    try {
      final fd = ref.read(listingFormProvider).formData;
      final repo = ref.read(listingRepositoryProvider);

      propertyId = await repo.createListing(fd.toSupabaseJson(user.id));
      await repo.uploadImages(propertyId, fd.photoBytes);
      await repo.addAmenities(propertyId, fd.amenities);

      ref.invalidate(myListingsProvider);
      notifier.reset();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 48,
            ),
            title: const Text('Listing Submitted'),
            content: const Text(
              'Your listing has been submitted for review. You can track it from My Listings.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.goNamed('myListings');
                },
                child: const Text('View My Listings'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (propertyId != null) {
        try {
          await ref.read(listingRepositoryProvider).deleteListing(propertyId);
        } catch (_) {
          // Best-effort rollback only.
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: ${_formatSubmissionError(error)}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomSafeArea = mediaQuery.padding.bottom;
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final fd = ref.watch(listingFormProvider).formData;
    final notifier = ref.read(listingFormProvider.notifier);
    final divisions = BdLocations.divisions;
    final districts = fd.division != null
        ? BdLocations.getDistricts(fd.division!)
        : <String>[];
    final areas = fd.district != null
        ? TheToletLocations.getAreas(fd.district!)
        : <String>[];
    final subAreas = fd.district != null && fd.thana != null
        ? TheToletLocations.getSubAreas(fd.district!, fd.thana!)
        : <String>[];

    return Stack(
      children: [
        SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            12,
            10,
            12,
            96 + bottomSafeArea + keyboardInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListingStep1Category(embedMode: true),
              const SizedBox(height: 14),
              const _SectionHeading(title: 'Premium Amenities'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: _amenityOptions.map((item) {
                  final isSelected = fd.amenities.contains(item.label);
                  return _AmenityChip(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => notifier.toggleAmenity(item.label),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _SectionHeading(
                title: 'Visual Gallery',
                trailing: 'Up to 10 photos',
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 760
                      ? 4
                      : constraints.maxWidth >= 520
                      ? 3
                      : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: fd.photoBytes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == fd.photoBytes.length) {
                        return _AddPhotoTile(
                          enabled:
                              !_isImportingPhotos && fd.photoBytes.length < 10,
                          onTap: _showPickerSheet,
                        );
                      }
                      return _PhotoTile(
                        imageBytes: fd.photoBytes[index],
                        isThumbnail: index == 0,
                        onRemove: () => notifier.removePhotoAt(index),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5EB),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Location Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 620;
                        final fieldWidth = twoColumns
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        final fields = [
                          _LocationDropdown(
                            label: 'Division',
                            value: fd.division,
                            hint: 'Choose division',
                            items: divisions,
                            onChanged: notifier.setDivision,
                          ),
                          _LocationDropdown(
                            label: 'District',
                            value: fd.district,
                            hint: 'Choose district',
                            items: districts,
                            onChanged: districts.isEmpty
                                ? null
                                : notifier.setDistrict,
                          ),
                          _LocationDropdown(
                            label: 'Area / Thana',
                            value: fd.thana,
                            hint: 'Choose area / thana',
                            items: areas,
                            onChanged: areas.isEmpty ? null : notifier.setThana,
                          ),
                          if (subAreas.isNotEmpty)
                            _LocationDropdown(
                              label: 'Sub Area',
                              value: subAreas.contains(fd.sector)
                                  ? fd.sector
                                  : null,
                              hint: 'Choose sub area',
                              items: subAreas,
                              onChanged: notifier.setSector,
                            ),
                          _LocationTextField(
                            label: 'Road / House No.',
                            scrollTargetKey: _roadFieldKey,
                            controller: _roadController,
                            focusNode: _roadFocusNode,
                            hintText: 'Road or house no.',
                            onChanged: notifier.setRoad,
                          ),
                          _LocationTextField(
                            label: 'House / Plot',
                            scrollTargetKey: _housePlotFieldKey,
                            controller: _housePlotController,
                            focusNode: _housePlotFocusNode,
                            hintText: 'e.g. Plot 7A',
                            onChanged: notifier.setHousePlot,
                          ),
                        ];

                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: fields
                              .map(
                                (field) =>
                                    SizedBox(width: fieldWidth, child: field),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _LocationTextField(
                      label: 'Contact Number',
                      scrollTargetKey: _contactFieldKey,
                      controller: _contactController,
                      fieldKey: const ValueKey('listing-step2-contact-field'),
                      focusNode: _contactFocusNode,
                      hintText: '01XXXXXXXXX',
                      keyboardType: TextInputType.phone,
                      onChanged: notifier.setContactNumber,
                    ),
                    const SizedBox(height: 10),
                    _LocationTextField(
                      label: 'Short Description',
                      scrollTargetKey: _descriptionFieldKey,
                      controller: _descriptionController,
                      focusNode: _descriptionFocusNode,
                      hintText: 'Describe the property briefly',
                      maxLines: 4,
                      onChanged: notifier.setShortDescription,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: KeyedSubtree(
            key: _stickyFooterKey,
            child: AnimatedPadding(
              key: _stickyFooterContextKey,
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Container(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + bottomSafeArea),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE7EBE1)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D631B), AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _isImportingPhotos
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: GoogleFonts.manrope(
                          fontSize: textScale > 1.15 ? 12 : 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _isSubmitting
                                  ? 'Submitting...'
                                  : _isImportingPhotos
                                  ? 'Preparing photos...'
                                  : 'Complete Listing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AmenityItem {
  const _AmenityItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null)
          Flexible(
            child: Text(
              trailing!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE0E4DA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo,
                size: 18,
                color: enabled ? AppColors.primary : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add Photo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: enabled ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.imageBytes,
    required this.isThumbnail,
    required this.onRemove,
  });

  final Uint8List imageBytes;
  final bool isThumbnail;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: Color(0xFFE0E4DA),
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
          if (isThumbnail)
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Thumbnail',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationDropdown extends StatelessWidget {
  const _LocationDropdown({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
  });

  final String label;
  final String? value;
  final String? hint;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null && items.isNotEmpty;
    final displayText = value?.trim().isNotEmpty == true
        ? value!
        : (hint ?? '');
    final textColor = value?.trim().isNotEmpty == true
        ? AppColors.textPrimary
        : AppColors.textHint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        InkWell(
          onTap: isEnabled
              ? () => _showLocationOptions(
                  context,
                  title: label,
                  items: items,
                  selectedValue: value,
                  onSelected: onChanged!,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.2,
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isEnabled
                      ? AppColors.textSecondary
                      : AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showLocationOptions(
  BuildContext context, {
  required String title,
  required List<String> items,
  required String? selectedValue,
  required ValueChanged<String?> onSelected,
}) async {
  final selected = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFE7EBE1)),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item == selectedValue;
                  return ListTile(
                    title: Text(
                      item,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(item),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );

  if (selected != null && context.mounted) {
    onSelected(selected);
  }
}

class _LocationTextField extends StatelessWidget {
  const _LocationTextField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.scrollTargetKey,
    this.fieldKey,
    this.focusNode,
    this.hintText,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Key? scrollTargetKey;
  final Key? fieldKey;
  final FocusNode? focusNode;
  final String? hintText;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: scrollTargetKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textAlignVertical: maxLines == 1
              ? TextAlignVertical.center
              : TextAlignVertical.top,
          decoration: _locationDecoration(hintText: hintText),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _AmenityItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final maxChipWidth = MediaQuery.sizeOf(context).width - 88;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5EB),
          borderRadius: BorderRadius.circular(999),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxChipWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _locationDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      color: AppColors.textHint,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    constraints: const BoxConstraints(minHeight: 54),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
