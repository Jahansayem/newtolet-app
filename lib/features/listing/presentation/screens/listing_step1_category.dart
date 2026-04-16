import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/listing_form_provider.dart';

/// Step 1 of the rebuilt Add Listing flow.
///
/// This screen combines the old category step and details step into a single
/// Stitch-inspired layout.
class ListingStep1Category extends ConsumerStatefulWidget {
  const ListingStep1Category({super.key, this.embedMode = false});

  final bool embedMode;

  @override
  ConsumerState<ListingStep1Category> createState() =>
      _ListingStep1CategoryState();
}

class _ListingStep1CategoryState extends ConsumerState<ListingStep1Category> {
  late final TextEditingController _roomSizeController;
  late final TextEditingController _rentController;

  static const _categories = [
    _CategoryItem(label: 'Family Home', icon: Icons.home),
    _CategoryItem(label: 'Bachelor', icon: Icons.person),
    _CategoryItem(label: 'Sublet', icon: Icons.bedroom_parent),
    _CategoryItem(label: 'Hostel/Mess', icon: Icons.groups_2),
    _CategoryItem(label: 'Office Space', icon: Icons.corporate_fare),
    _CategoryItem(label: 'Shop', icon: Icons.storefront),
  ];

  static const _propertyTypes = [
    'Apartment',
    'Unit',
    'House',
    'Office Space',
    'Shop',
    'Warehouse',
    'Factory',
    'Hostel',
    'Hotel',
    'Building',
  ];

  static const _occupancyTypes = [
    'Family',
    'Male',
    'Female',
    'No Restrictions',
  ];

  static const _floorLevels = [
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
    '4th Floor',
    '5th Floor',
    '6th Floor',
    '7th Floor',
    '8th Floor',
    '9th Floor',
    '10th Floor',
    '11th Floor',
    '12th Floor',
    '13th Floor',
    '14th Floor',
    '15th Floor',
    '16th Floor',
    '17th Floor',
    '18th Floor',
    '19th Floor',
    '20th Floor',
  ];

  static const _rentPeriods = ['Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    final fd = ref.read(listingFormProvider).formData;
    _roomSizeController = TextEditingController(
      text: fd.roomSizeSqft?.toString() ?? '',
    );
    _rentController = TextEditingController(
      text: fd.rentAmountBdt?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _roomSizeController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fd = ref.watch(listingFormProvider).formData;
    final notifier = ref.read(listingFormProvider.notifier);

    final content = Padding(
      padding: widget.embedMode
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionIntro(
            title: 'Select Category',
            subtitle: 'Choose the type of listing you want to create.',
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            childAspectRatio: 1.42,
            children: _categories.map((cat) {
              final isSelected = fd.category == cat.label;
              return _CategoryCard(
                item: cat,
                isSelected: isSelected,
                onTap: () => notifier.setCategory(cat.label),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5EB),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(title: 'Property Type', marginBottom: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _propertyTypes.map((type) {
                    return _ChoicePill(
                      label: type,
                      selected: fd.propertyType == type,
                      onTap: () => notifier.setPropertyType(type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _SectionLabel(title: 'Allowed For', marginBottom: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _occupancyTypes.map((type) {
                    return _ChoicePill(
                      label: type,
                      selected: fd.occupancy == type,
                      onTap: () => notifier.setOccupancy(type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 620;
                    final fieldWidth = twoColumns
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    final counterTiles = [
                      _CounterTile(
                        icon: Icons.bed,
                        label: 'Total Rooms',
                        value: fd.totalRooms,
                        min: 1,
                        max: 20,
                        onChanged: notifier.setTotalRooms,
                      ),
                      _CounterTile(
                        icon: Icons.shower,
                        label: 'Total Bathrooms',
                        value: fd.totalBathrooms,
                        min: 0,
                        max: 10,
                        onChanged: notifier.setTotalBathrooms,
                      ),
                      _CounterTile(
                        icon: Icons.soup_kitchen,
                        label: 'Total Kitchen',
                        value: fd.totalKitchen,
                        min: 0,
                        max: 5,
                        onChanged: notifier.setTotalKitchen,
                      ),
                      _CounterTile(
                        icon: Icons.balcony,
                        label: 'Balcony',
                        value: fd.balcony,
                        min: 0,
                        max: 10,
                        onChanged: notifier.setBalcony,
                      ),
                    ];

                    return Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: counterTiles
                          .map(
                            (tile) => SizedBox(width: fieldWidth, child: tile),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _TickOption(
                      label: 'Dining Room',
                      selected: fd.amenities.contains('Dining Room'),
                      onTap: () => notifier.toggleAmenity('Dining Room'),
                    ),
                    _TickOption(
                      label: 'Drawing Room',
                      selected: fd.amenities.contains('Drawing Room'),
                      onTap: () => notifier.toggleAmenity('Drawing Room'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 620;
                    final fieldWidth = twoColumns
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    final fields = [
                      _StyledDropdown<String>(
                        label: 'Floor Level',
                        value: fd.floorLevel,
                        hint: 'Select floor level',
                        items: _floorLevels
                            .map(
                              (level) => DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ),
                            )
                            .toList(),
                        onChanged: notifier.setFloorLevel,
                      ),
                      _StyledTextField(
                        label: 'Room Size (sqft) Optional',
                        controller: _roomSizeController,
                        hintText: 'Optional, e.g. 1200',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          notifier.setRoomSizeSqft(int.tryParse(value));
                        },
                      ),
                      _StyledTextField(
                        label: 'Rent Amount (BDT)',
                        controller: _rentController,
                        hintText: fd.isRentNegotiable
                            ? 'Enter amount, negotiable label stays on'
                            : 'e.g. 25000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        trailing: _TickOption(
                          label: 'Negotiable',
                          selected: fd.isRentNegotiable,
                          compact: true,
                          onTap: () =>
                              notifier.setRentNegotiable(!fd.isRentNegotiable),
                        ),
                        onChanged: (value) {
                          notifier.setRentAmountBdt(int.tryParse(value));
                        },
                      ),
                      _StyledDropdown<String>(
                        label: 'Rent Period',
                        value: fd.rentPeriod,
                        items: _rentPeriods
                            .map(
                              (period) => DropdownMenuItem(
                                value: period,
                                child: Text(period),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            notifier.setRentPeriod(value);
                          }
                        },
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
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.embedMode) {
      return content;
    }

    return SingleChildScrollView(child: content);
  }
}

class _CategoryItem {
  const _CategoryItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.marginBottom = 0});

  final String title;
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _CategoryItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : const Color(0xFFE0E4DA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFE0E4DA),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.remove,
            enabled: value > min,
            filled: false,
            onTap: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 30,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add,
            enabled: value < max,
            filled: true,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _TickOption extends StatelessWidget {
  const _TickOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: compact ? 16 : 20,
            height: compact ? 16 : 20,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                width: 1.4,
              ),
            ),
            child: selected
                ? Icon(
                    Icons.check,
                    size: compact ? 10 : 13,
                    color: Colors.white,
                  )
                : null,
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.enabled,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = !enabled
        ? const Color(0xFFE0E4DA)
        : filled
        ? AppColors.primary
        : const Color(0xFFE0E4DA);
    final iconColor = !enabled
        ? AppColors.textHint
        : filled
        ? Colors.white
        : AppColors.primary;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: iconColor),
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
  });

  final String label;
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        DropdownButtonFormField<T>(
          initialValue: value,
          hint: hint == null ? null : Text(hint!),
          items: items,
          onChanged: onChanged,
          decoration: _fieldDecoration(),
          borderRadius: BorderRadius.circular(18),
          isDense: true,
          dropdownColor: Colors.white,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final headerChildren = <Widget>[
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ];

    if (trailing != null) {
      headerChildren.add(trailing!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(children: headerChildren),
        ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: _fieldDecoration(hintText: hintText),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration({String? hintText, bool enabled = true}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      color: AppColors.textHint,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: enabled ? const Color(0xFFE0E4DA) : const Color(0xFFECEFE8),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
