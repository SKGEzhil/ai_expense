import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/settings_service.dart';
import '../../utils/theme.dart';

/// Settings page for app configuration
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  SettingsService? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await SettingsService.getInstance();
    _urlController.text = _settings!.baseUrl;
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    await _settings?.setBaseUrl(_urlController.text.trim());
    setState(() => _isSaving = false);

    Get.snackbar(
      'Settings Saved',
      'App restart may be required for changes to take effect',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successColor.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  Future<void> _resetToDefaults() async {
    await _settings?.resetToDefaults();
    _urlController.text = _settings!.baseUrl;
    setState(() {});

    Get.snackbar(
      'Reset Complete',
      'Settings have been reset to defaults',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.9),
      colorText: Colors.white,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
        ),
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Server Settings Section
                  _buildSectionTitle('Server Settings'),
                  const SizedBox(height: 16),
                  _buildSettingCard(
                    title: 'API Base URL',
                    subtitle: 'The backend server address',
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'http://localhost:8000',
                        hintStyle: TextStyle(
                          color: AppTheme.textMuted.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Reset Section
                  _buildSectionTitle('Reset'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _resetToDefaults,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset to Defaults'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App Info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'AI Expense Tracker',
                          style: TextStyle(
                            color: AppTheme.textMuted.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            color: AppTheme.textMuted.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
