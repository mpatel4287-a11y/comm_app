// lib/screens/user/settings_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/session_manager.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/theme_service.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String? _familyName;
  String? _familyId;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final familyName = await SessionManager.getFamilyName();
    final familyId = await SessionManager.getFamilyId();
    final role = await SessionManager.getRole();

    setState(() {
      _familyName = familyName;
      _familyId = familyId?.toString();
      _role = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageService>(context);
    final theme = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('settings')),
        backgroundColor: Colors.blue.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSectionHeader(lang.translate('profile')),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(_familyName ?? 'User'),
              subtitle: Text(
                'ID: ${_familyId ?? "N/A"} • ${_role ?? "member"}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to profile edit
              },
            ),
          ),
          const SizedBox(height: 24),

          // Preferences Section
          _buildSectionHeader(lang.translate('preferences')),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(lang.translate('notifications')),
                  subtitle: Text(lang.translate('receive_notifications')),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(lang.translate('dark_mode')),
                  subtitle: Text(lang.translate('use_dark_theme')),
                  value: theme.isDarkMode,
                  onChanged: (value) {
                    theme.toggleTheme();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Language Section
          _buildSectionHeader(lang.translate('language')),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('English'),
                  trailing: lang.currentLanguage == 'en' ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () => lang.setLanguage('en'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('ગુજરાતી (Gujarati)'),
                  trailing: lang.currentLanguage == 'gu' ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () => lang.setLanguage('gu'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Family Section
          _buildSectionHeader(lang.translate('family')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.people),
                  title: Text(lang.translate('view_family_members')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/familyMembers');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.badge_rounded),
                  title: Text(lang.translate('digital_id')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Logic to open self digital ID
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader(lang.translate('support')),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help),
                  title: Text(lang.translate('help_faq')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Open help
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(lang.translate('about')),
                  subtitle: const Text('Community App v1.2'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Community App',
                      applicationVersion: '1.2.0',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(lang.translate('logout')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _showLogoutDialog(lang),
          ),
          const SizedBox(height: 16),

          // Version Info
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(LanguageService lang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.translate('logout')),
        content: Text(lang.translate('confirm_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.translate('logout')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
