import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/property_filter_provider.dart';

/// Expandable search bar that debounces input and updates
/// [propertyFilterProvider.searchQuery].
///
/// Supports both Bangla and English text input.
class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _isExpanded = false;

  late final AnimationController _animController;
  late final Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(propertyFilterProvider.notifier).setSearch(value);
    });
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animController.forward();
      _focusNode.requestFocus();
    } else {
      _animController.reverse();
      _controller.clear();
      _focusNode.unfocus();
      ref.read(propertyFilterProvider.notifier).setSearch(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizeTransition(
          sizeFactor: _widthAnimation,
          axis: Axis.horizontal,
          axisAlignment: -1,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.55,
            height: 40,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search properties...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: AppColors.scaffoldBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _controller.clear();
                          ref
                              .read(propertyFilterProvider.notifier)
                              .setSearch(null);
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            _isExpanded ? Icons.close : Icons.search,
            color: AppColors.textPrimary,
          ),
          tooltip: _isExpanded ? 'Close search' : 'Search',
          onPressed: _toggleSearch,
        ),
      ],
    );
  }
}
