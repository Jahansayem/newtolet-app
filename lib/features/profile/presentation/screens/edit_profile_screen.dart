import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/data/bd_locations.dart';
import '../../../../shared/providers/current_user_provider.dart';
import '../../data/profile_repository.dart';

/// Edit profile form pre-filled with the user's current data.
///
/// On save, updates the `users` table via [ProfileRepository] and refreshes
/// the [currentUserProvider] so the rest of the app reflects the changes.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bkashController;
  late TextEditingController _nagadController;

  String? _selectedDivision;
  String? _selectedDistrict;

  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _bkashController = TextEditingController();
    _nagadController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bkashController.dispose();
    _nagadController.dispose();
    super.dispose();
  }

  /// Pre-fills form fields from the current user model.
  void _initializeFields() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || _initialized) return;
    _initialized = true;

    _nameController.text = user.name ?? '';
    _phoneController.text = user.phone ?? '';
    _bkashController.text = user.bkashNumber ?? '';
    _nagadController.text = user.nagadNumber ?? '';
    _selectedDivision = user.division;
    _selectedDistrict = user.district;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }

          _initializeFields();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // -- Name ---------------------------------------------------
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // -- Phone --------------------------------------------------
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '01XXXXXXXXX',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // -- bKash --------------------------------------------------
                  TextFormField(
                    controller: _bkashController,
                    decoration: const InputDecoration(
                      labelText: 'bKash Number',
                      prefixIcon: Icon(Icons.phone_android),
                      hintText: '01XXXXXXXXX',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // -- Nagad --------------------------------------------------
                  TextFormField(
                    controller: _nagadController,
                    decoration: const InputDecoration(
                      labelText: 'Nagad Number',
                      prefixIcon: Icon(Icons.phone_android),
                      hintText: '01XXXXXXXXX',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // -- Division -----------------------------------------------
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDivision,
                    decoration: const InputDecoration(
                      labelText: 'Division',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: BdLocations.divisions
                        .map(
                          (d) => DropdownMenuItem(value: d, child: Text(d)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDivision = value;
                        _selectedDistrict = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // -- District -----------------------------------------------
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'District',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: _selectedDivision != null
                        ? BdLocations.getDistricts(_selectedDivision!)
                            .map(
                              (d) =>
                                  DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList()
                        : [],
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                      });
                    },
                    hint: Text(
                      _selectedDivision == null
                          ? 'Select division first'
                          : 'Select district',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // -- Save button --------------------------------------------
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _handleSave,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save handler
  // ---------------------------------------------------------------------------

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final repository = ref.read(profileRepositoryProvider);

      await repository.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        bkashNumber: _bkashController.text.trim().isNotEmpty
            ? _bkashController.text.trim()
            : null,
        nagadNumber: _nagadController.text.trim().isNotEmpty
            ? _nagadController.text.trim()
            : null,
        division: _selectedDivision,
        district: _selectedDistrict,
      );

      // Refresh the global user provider so all screens reflect the update.
      await ref.read(currentUserProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
