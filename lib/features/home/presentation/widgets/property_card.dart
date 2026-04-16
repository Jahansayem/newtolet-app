import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../models/property_model.dart';
import '../../providers/properties_provider.dart';

/// A compact card displaying a property listing in the home grid.
///
/// Shows thumbnail image, price, category, location, and quick specs.
/// Tapping navigates to the property detail screen.
class PropertyCard extends ConsumerWidget {
  const PropertyCard({required this.property, super.key});

  final PropertyModel property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        context.goNamed(
          RouteNames.propertyDetail,
          pathParameters: {'id': property.id},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Image section --
            _ImageSection(
              property: property,
              onFavoriteToggle: () {
                ref
                    .read(propertiesProvider.notifier)
                    .toggleFavorite(property.id);
              },
            ),

            // -- Info section --
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      property.isRentNegotiable
                          ? 'Negotiable'
                          : property.rentAmountBdt != null
                          ? Formatters.formatBDT(
                              property.rentAmountBdt!.toDouble(),
                            )
                          : 'Contact for price',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!property.isRentNegotiable &&
                        property.rentPeriod != null)
                      Text(
                        '/${property.rentPeriod}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            property.shortLocation,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Specs row
                    Row(
                      children: [
                        if (property.totalRooms != null) ...[
                          _SpecIcon(
                            icon: Icons.bed_outlined,
                            label: '${property.totalRooms}',
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (property.totalBathrooms != null)
                          _SpecIcon(
                            icon: Icons.bathtub_outlined,
                            label: '${property.totalBathrooms}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image section with thumbnail, price badge, category chip, favorite button
// ---------------------------------------------------------------------------

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.property, required this.onFavoriteToggle});

  final PropertyModel property;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          if (property.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: property.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(color: Colors.white),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(
                  Icons.home_outlined,
                  size: 40,
                  color: AppColors.textHint,
                ),
              ),
            )
          else
            Container(
              color: AppColors.surfaceVariant,
              child: const Icon(
                Icons.home_outlined,
                size: 40,
                color: AppColors.textHint,
              ),
            ),

          // Category chip (top-left)
          if (property.category != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  property.category!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),

          // Favorite button (top-right)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onFavoriteToggle,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    property.isFavorited
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 18,
                    color: property.isFavorited
                        ? Colors.redAccent
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small spec icon + label used in the bottom row
// ---------------------------------------------------------------------------

class _SpecIcon extends StatelessWidget {
  const _SpecIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
