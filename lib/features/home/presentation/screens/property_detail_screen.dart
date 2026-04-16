import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/current_user_provider.dart';
import '../../data/property_repository.dart';
import '../../models/property_model.dart';
import '../../providers/properties_provider.dart';

/// Full property detail page showing images, specs, amenities, location,
/// and contact information.
class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({required this.propertyId, super.key});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  final _pageController = PageController();
  int _currentImageIndex = 0;
  bool _viewIncremented = false;

  @override
  void initState() {
    super.initState();
    _incrementViews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _incrementViews() async {
    if (_viewIncremented) return;
    _viewIncremented = true;
    try {
      await ref
          .read(propertyRepositoryProvider)
          .incrementViews(widget.propertyId);
    } catch (_) {
      // Non-critical -- fail silently.
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProperty = ref.watch(propertyDetailProvider(widget.propertyId));

    return Scaffold(
      body: asyncProperty.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load property',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(propertyDetailProvider(widget.propertyId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (property) => _DetailBody(
          property: property,
          pageController: _pageController,
          currentImageIndex: _currentImageIndex,
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail body
// ---------------------------------------------------------------------------

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.property,
    required this.pageController,
    required this.currentImageIndex,
    required this.onPageChanged,
  });

  final PropertyModel property;
  final PageController pageController;
  final int currentImageIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final dateFormat = DateFormat('dd MMM yyyy');
    final mediaQuery = MediaQuery.of(context);

    return CustomScrollView(
      slivers: [
        // -- Image carousel in SliverAppBar --
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          actions: [
            // Favorite button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                child: IconButton(
                  icon: Icon(
                    property.isFavorited
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: property.isFavorited
                        ? Colors.redAccent
                        : Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    ref
                        .read(propertiesProvider.notifier)
                        .toggleFavorite(property.id);
                    // Also invalidate detail cache.
                    ref.invalidate(propertyDetailProvider(property.id));
                  },
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Image carousel
                if (property.imageUrls.isNotEmpty)
                  PageView.builder(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    itemCount: property.imageUrls.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: property.imageUrls[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.broken_image,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(
                      Icons.home_outlined,
                      size: 64,
                      color: AppColors.textHint,
                    ),
                  ),

                // Gradient overlay for readability
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // Page indicator dots
                if (property.imageUrls.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        property.imageUrls.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: index == currentImageIndex ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: index == currentImageIndex
                                ? Colors.white
                                : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Price badge
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      property.isRentNegotiable
                          ? 'Negotiable'
                          : property.rentAmountBdt != null
                          ? '${Formatters.formatBDT(property.rentAmountBdt!.toDouble())}${property.rentPeriod != null ? "/${property.rentPeriod}" : ""}'
                          : 'Contact for price',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // -- Property details --
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title / description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        property.shortDescription ?? 'Property Listing',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (property.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.category!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.locationText.isNotEmpty
                            ? property.locationText
                            : 'Location not specified',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Address details
                if (property.sector != null ||
                    property.road != null ||
                    property.housePlot != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      [
                        if (property.housePlot != null)
                          'House/Plot: ${property.housePlot}',
                        if (property.road != null) 'Road: ${property.road}',
                        if (property.sector != null)
                          'Sub Area: ${property.sector}',
                      ].join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 4),

                // Views count
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${property.views} views',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // -- Property specs row --
                const Text(
                  'Property Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _SpecsGrid(property: property),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // -- Amenities --
                if (property.amenities.isNotEmpty) ...[
                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: property.amenities.map((amenity) {
                      return Chip(
                        avatar: Icon(
                          _amenityIcon(amenity),
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          amenity,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppColors.surfaceVariant,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],

                // -- Availability dates --
                if (property.availableFrom != null ||
                    property.deadline != null) ...[
                  const Text(
                    'Availability',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (property.availableFrom != null)
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Available From',
                            value: dateFormat.format(property.availableFrom!),
                          ),
                        ),
                      if (property.availableFrom != null &&
                          property.deadline != null)
                        const SizedBox(width: 12),
                      if (property.deadline != null)
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.event_busy_outlined,
                            label: 'Deadline',
                            value: dateFormat.format(property.deadline!),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],

                // -- Map section --
                if (property.lat != null && property.lng != null) ...[
                  const Text(
                    'Location on Map',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MapPreview(lat: property.lat!, lng: property.lng!),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],

                // -- Contact section --
                const Text(
                  'Contact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                currentUser.when(
                  data: (user) {
                    if (user == null) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sign in to view contact information',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final phone = property.contactNumber;
                    if (phone == null || phone.isEmpty) {
                      return const Text(
                        'No contact number available',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      );
                    }

                    return _ContactSection(phone: phone);
                  },
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => const Text(
                    'Unable to verify login status',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                // Bottom spacing for safety
                SizedBox(height: mediaQuery.padding.bottom + 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Specs grid
// ---------------------------------------------------------------------------

class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.property});

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    final specs = <_SpecItem>[];

    if (property.totalRooms != null) {
      specs.add(
        _SpecItem(
          icon: Icons.bed_outlined,
          label: 'Rooms',
          value: '${property.totalRooms}',
        ),
      );
    }
    if (property.totalBathrooms != null) {
      specs.add(
        _SpecItem(
          icon: Icons.bathtub_outlined,
          label: 'Bathrooms',
          value: '${property.totalBathrooms}',
        ),
      );
    }
    if (property.totalKitchen != null) {
      specs.add(
        _SpecItem(
          icon: Icons.kitchen_outlined,
          label: 'Kitchen',
          value: '${property.totalKitchen}',
        ),
      );
    }
    if (property.balcony != null) {
      specs.add(
        _SpecItem(
          icon: Icons.balcony_outlined,
          label: 'Balcony',
          value: '${property.balcony}',
        ),
      );
    }
    if (property.floorLevel != null) {
      specs.add(
        _SpecItem(
          icon: Icons.layers_outlined,
          label: 'Floor',
          value: property.floorLevel!,
        ),
      );
    }
    if (property.roomSizeSqft != null) {
      specs.add(
        _SpecItem(
          icon: Icons.square_foot_outlined,
          label: 'Size',
          value: '${property.roomSizeSqft} sqft',
        ),
      );
    }
    if (property.occupancy != null) {
      specs.add(
        _SpecItem(
          icon: Icons.people_outline,
          label: 'Occupancy',
          value: property.occupancy!,
        ),
      );
    }
    if (property.propertyType != null) {
      specs.add(
        _SpecItem(
          icon: Icons.home_work_outlined,
          label: 'Type',
          value: property.propertyType!,
        ),
      );
    }

    if (specs.isEmpty) {
      return const Text(
        'No details available',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: specs
          .map(
            (spec) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(spec.icon, size: 22, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Text(
                    spec.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    spec.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SpecItem {
  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

// ---------------------------------------------------------------------------
// Info tile (availability dates)
// ---------------------------------------------------------------------------

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map preview
// ---------------------------------------------------------------------------

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    // Use a static map image via Google Maps Static API placeholder.
    // For a fully interactive map, replace this with GoogleMap widget.
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Map placeholder with coordinates
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to open in Google Maps',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Pin icon overlay
            const Positioned(
              top: 16,
              child: Icon(Icons.location_on, size: 32, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contact section
// ---------------------------------------------------------------------------

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final formatted = Formatters.formatPhoneNumber(phone);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Phone icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),

          // Phone number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phone Number',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
                const SizedBox(height: 2),
                Text(
                  formatted,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Call button
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.primary),
            tooltip: 'Call',
            onPressed: () async {
              final uri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),

          // Copy button
          IconButton(
            icon: const Icon(
              Icons.copy,
              color: AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Copy number',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phone));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number copied'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Amenity icon mapping
// ---------------------------------------------------------------------------

IconData _amenityIcon(String amenity) {
  final lower = amenity.toLowerCase();
  if (lower.contains('gas')) return Icons.local_fire_department_outlined;
  if (lower.contains('water')) return Icons.water_drop_outlined;
  if (lower.contains('lift') || lower.contains('elevator')) {
    return Icons.elevator_outlined;
  }
  if (lower.contains('parking')) return Icons.local_parking_outlined;
  if (lower.contains('wifi') || lower.contains('internet')) {
    return Icons.wifi_outlined;
  }
  if (lower.contains('generator') || lower.contains('power')) {
    return Icons.bolt_outlined;
  }
  if (lower.contains('security') || lower.contains('guard')) {
    return Icons.security_outlined;
  }
  if (lower.contains('dining')) return Icons.table_restaurant_outlined;
  if (lower.contains('drawing') || lower.contains('living')) {
    return Icons.weekend_outlined;
  }
  if (lower.contains('gym') || lower.contains('exercise')) {
    return Icons.fitness_center_outlined;
  }
  if (lower.contains('pool') || lower.contains('swim')) {
    return Icons.pool_outlined;
  }
  if (lower.contains('garden') || lower.contains('roof')) {
    return Icons.yard_outlined;
  }
  if (lower.contains('ac') || lower.contains('air')) {
    return Icons.ac_unit_outlined;
  }
  if (lower.contains('cctv') || lower.contains('camera')) {
    return Icons.videocam_outlined;
  }
  if (lower.contains('laundry') || lower.contains('wash')) {
    return Icons.local_laundry_service_outlined;
  }
  if (lower.contains('servant') || lower.contains('maid')) {
    return Icons.cleaning_services_outlined;
  }
  return Icons.check_circle_outline;
}
