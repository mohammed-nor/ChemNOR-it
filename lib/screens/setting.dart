/// A settings page that allows users to configure application preferences.
///
/// This page provides the following features:
/// - Select the Large Language Model (LLM) to use from available Gemini models.
/// - Enter and save a Gemini API key.
/// - Display the currently used API key (either the user-provided key or a default key).
/// - Adjust the font size using a slider.
library;

// Import necessary packages
import 'package:chem_nor/chem_nor.dart'; // For GeminiModel enum
import 'package:chemnor_it/main.dart'; // App configuration
import 'package:chemnor_it/services/ChemnorApi.dart'; // For manual re-initialization
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:hive/hive.dart'; // For persistent storage access
import 'package:hive_flutter/hive_flutter.dart'; // For Hive Flutter integration
import 'package:url_launcher/url_launcher.dart';

// Import local settings controller
import '../screens/settings_controller.dart';

/// Main settings page widget
class SettingPage extends StatefulWidget {
  // Constructor with key parameter for widget identification
  const SettingPage({super.key});

  @override
  // Create state for this widget
  State<SettingPage> createState() => _SettingsPageState();
}

/// State class for the settings page
class _SettingsPageState extends State<SettingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  // Store current app settings
  late AppSettings _settings;

  // Define available LLM models as a list
  // This shows all available Gemini models that the app can use
  final List<GeminiModel> llmModels = [
    GeminiModel.gemini2_5FlashLite,
    GeminiModel.gemini3_0Flash,
    GeminiModel.gemini3_0Pro,
    GeminiModel.gemini2_5Pro,
    GeminiModel.gemini2_5Flash,
  ];

  @override
  // Initialize state when widget is created
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Get current settings from the controller
    _settings = settingsController.value;

    // Safety check: if selected model isn't in our list, use a default
    if (!llmModels.contains(_settings.selectedModel)) {
      _updateSettings(selectedModel: llmModels[1]); // Default to second model
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Method to update settings via the controller
  void _updateSettings({
    GeminiModel? selectedModel,
    double? fontSize,
    num? diversity,
    String? geminiApiKey,
  }) {
    // Update settings using the controller
    // Update settings using the controller
    settingsController.updateField(
      selectedModel: selectedModel ?? _settings.selectedModel,
      fontSize: fontSize,
      diversity: diversity,
      geminiApiKey: geminiApiKey,
    );

    // Persist changes to Hive
    final box = Hive.box('settingBox');
    if (selectedModel != null) {
      box.put('selectedModel', AppSettings.geminiModelToString(selectedModel));
    }
    if (geminiApiKey != null) {
      box.put('geminiApiKey', geminiApiKey);
    }
    if (fontSize != null) {
      box.put('fontSize', fontSize);
    }
    if (diversity != null) {
      box.put('diversity', diversity);
    }

    // Update local state to reflect changes
    setState(() {
      _settings = settingsController.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseFontSize = settingsController.value.fontSize;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Premium Designed Background
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF020617)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -120,
                    left: -120,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    right: -150,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4F46E5).withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'ChemNOR ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: baseFontSize + 4.0,
                          ),
                        ),
                        TextSpan(
                          text: 'it! ',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.redAccent,
                            fontSize: baseFontSize,
                          ),
                        ),
                        TextSpan(
                          text: 'Settings',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: baseFontSize,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Developer Profile Section
                      _buildSectionTitle('Developer'),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'images/1.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) =>
                                          Icon(Icons.person, size: 40),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NOR MOHAMMED',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: baseFontSize + 4.0,
                                        ),
                                      ),
                                      Text(
                                        'nour1608@gmail.com',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: baseFontSize,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildSocialButton(
                                            baseFontSize: baseFontSize,
                                            icon: Icons.link_rounded,
                                            label: 'GitHub',
                                            onTap: () => launchUrl(
                                              Uri.parse(
                                                "https://github.com/mohammed-nor",
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // AI Configuration Section
                      _buildSectionTitle('AI Configuration'),
                      _buildSettingCard(
                        baseFontSize: baseFontSize,
                        title: 'LLM Model',
                        subtitle: 'Choose the Gemini model for processing',
                        icon: Icons.psychology_rounded,
                        child: DropdownButtonHideUnderline(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<GeminiModel>(
                              value: _settings.selectedModel,
                              dropdownColor: theme.colorScheme.surface,
                              icon: Icon(Icons.keyboard_arrow_down_rounded),
                              items: llmModels.map((GeminiModel model) {
                                return DropdownMenuItem<GeminiModel>(
                                  value: model,
                                  child: Text(
                                    model.name,
                                    style: TextStyle(fontSize: baseFontSize),
                                  ),
                                );
                              }).toList(),
                              onChanged: (GeminiModel? newValue) {
                                if (newValue != null) {
                                  _updateSettings(selectedModel: newValue);
                                  Hive.box('settingBox').put(
                                    'selectedModel',
                                    AppSettings.geminiModelToString(newValue),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingCard(
                        baseFontSize: baseFontSize,
                        title: 'API Key',
                        subtitle: 'Configure your Gemini API key',
                        icon: Icons.vpn_key_rounded,
                        child: Column(
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Enter API Key',
                                prefixIcon: Icon(Icons.key_rounded, size: 20),
                                suffixIcon: _settings.geminiApiKey.isNotEmpty
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green.shade400,
                                        size: 20,
                                      )
                                    : null,
                              ),
                              controller: TextEditingController(
                                text: _settings.geminiApiKey,
                              ),
                              style: TextStyle(fontSize: baseFontSize),
                              onSubmitted: (value) =>
                                  _updateSettings(geminiApiKey: value),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse(
                                  "https://aistudio.google.com/app/api-keys",
                                ),
                              ),
                              icon: Icon(Icons.open_in_new_rounded, size: 16),
                              label: Text('Get API Key'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.1),
                                foregroundColor: theme.colorScheme.primary,
                                minimumSize: const Size(double.infinity, 44),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ChemnorApi().reinitiate();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'ChemNOR Model Reinitiated!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                icon: Icon(Icons.refresh_rounded, size: 18),
                                label: Text('Reinitiate Model'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                  ),
                                  foregroundColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize: const Size(double.infinity, 44),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Interface Settings Section
                      _buildSectionTitle(
                        'Interface',
                        baseFontSize: baseFontSize,
                      ),
                      _buildSettingCard(
                        baseFontSize: baseFontSize,
                        title: 'Font Size',
                        subtitle: 'Adjust app-wide text scaling',
                        icon: Icons.format_size_rounded,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'A',
                                  style: TextStyle(
                                    fontSize: baseFontSize - 2.0,
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _settings.fontSize,
                                    min: 10.0,
                                    max: 30.0,
                                    activeColor: theme.colorScheme.primary,
                                    onChanged: (double value) =>
                                        _updateSettings(fontSize: value),
                                  ),
                                ),
                                Text(
                                  'A',
                                  style: TextStyle(
                                    fontSize: baseFontSize + 10.0,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_settings.fontSize.toStringAsFixed(1)} px',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: baseFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {double baseFontSize = 16.0}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: baseFontSize - 2.0,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    double baseFontSize = 16.0,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: baseFontSize + 2.0,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: baseFontSize - 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double baseFontSize = 16.0,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: baseFontSize - 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
