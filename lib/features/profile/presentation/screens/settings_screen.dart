import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';

/// Settings screen providing language, notification, and data-saver toggles
/// as well as app information and a (placeholder) delete-account action.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _keyLanguage = 'settings_language_bangla';
  static const _keyNotifications = 'settings_push_notifications';
  static const _keyDataSaver = 'settings_data_saver';

  bool _isBangla = false;
  bool _pushNotifications = true;
  bool _dataSaver = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBangla = prefs.getBool(_keyLanguage) ?? false;
      _pushNotifications = prefs.getBool(_keyNotifications) ?? true;
      _dataSaver = prefs.getBool(_keyDataSaver) ?? false;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // -- Language -------------------------------------------------------
          _SectionHeader(title: 'Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.language, color: AppColors.primary),
            title: const Text('Bangla Language'),
            subtitle: Text(
              _isBangla ? 'Bangla enabled' : 'English (default)',
              style: theme.textTheme.bodySmall,
            ),
            value: _isBangla,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _isBangla = value);
              _saveBool(_keyLanguage, value);
            },
          ),
          const Divider(height: 1, indent: 72),

          // -- Push notifications ---------------------------------------------
          SwitchListTile(
            secondary:
                const Icon(Icons.notifications_outlined, color: AppColors.primary),
            title: const Text('Push Notifications'),
            subtitle: Text(
              _pushNotifications ? 'Enabled' : 'Disabled',
              style: theme.textTheme.bodySmall,
            ),
            value: _pushNotifications,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
              _saveBool(_keyNotifications, value);
            },
          ),
          const Divider(height: 1, indent: 72),

          // -- Data saver -----------------------------------------------------
          SwitchListTile(
            secondary: const Icon(Icons.data_saver_on_outlined,
                color: AppColors.primary),
            title: const Text('Data Saver Mode'),
            subtitle: Text(
              _dataSaver
                  ? 'Reduces image quality to save data'
                  : 'Full quality images',
              style: theme.textTheme.bodySmall,
            ),
            value: _dataSaver,
            activeTrackColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _dataSaver = value);
              _saveBool(_keyDataSaver, value);
            },
          ),

          const SizedBox(height: 16),

          // -- About ----------------------------------------------------------
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.primary),
            title: const Text('App Version'),
            subtitle: const Text('0.1.0+1'),
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: const Icon(Icons.mail_outline, color: AppColors.primary),
            title: const Text('Contact Support'),
            subtitle: const Text('support@newtolet.com'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening email client...')),
              );
            },
          ),

          const SizedBox(height: 16),

          // -- Danger zone ----------------------------------------------------
          _SectionHeader(title: 'Danger Zone'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined,
                color: AppColors.error),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: Text(
              'Permanently delete your account and data',
              style: theme.textTheme.bodySmall,
            ),
            onTap: () => _showDeleteAccountDialog(context),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete account dialog
  // ---------------------------------------------------------------------------

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is irreversible. All your data, points, and earnings '
          'will be permanently deleted. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deletion request submitted. '
                    'Our team will contact you shortly.',
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Section header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
