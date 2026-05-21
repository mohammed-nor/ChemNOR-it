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
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:share_plus/share_plus.dart';
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
class _SettingsPageState extends State<SettingPage> {
  // Store current app settings
  late AppSettings _settings;
  // Controller for the API key text field - must be state-level to avoid accessibility tree desync
  late TextEditingController _apiKeyController;

  // Define available LLM models from the chem_nor package, filtering out duplicates
  final List<GeminiModel> llmModels = () {
    final seen = <String>{};
    return GeminiModel.values
        .where((model) => seen.add(model.apiName))
        .toList();
  }();

  @override
  // Initialize state when widget is created
  void initState() {
    super.initState();
    // Get current settings from the controller
    _settings = settingsController.value;

    // Initialize the API key controller once with the current value
    _apiKeyController = TextEditingController(text: _settings.geminiApiKey);

    // Safety check: if selected model isn't in our list, use a default
    if (!llmModels.contains(_settings.selectedModel)) {
      _updateSettings(selectedModel: llmModels[1]); // Default to second model
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
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

    // Update local state to reflect changes
    setState(() {
      _settings = settingsController.value;
    });
  }

  Future<void> _shareApp() async {
    const appLink =
        'https://play.google.com/store/apps/dev?id=6694339020319831911';
    const message =
        '📱 Check out ChemNOR it!\n\n🔗 Download the app here:\n$appLink\n\n✨ A smart chemistry assistant for compounds, search, and analysis.';

    try {
      await Share.share(message, subject: 'ChemNOR it! App');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open share dialog'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse(
      'mailto:nor.it.services@gmail.com?subject=${Uri.encodeComponent('Check out ChemNOR it!')}&body=${Uri.encodeComponent('I thought you might be interested in ChemNOR it!')}',
    );
    try {
      await launchUrl(uri);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email client')),
      );
    }
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/dev?id=6694339020319831911',
    );
    try {
      await launchUrl(uri);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Play Store')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseFontSize = settingsController.value.fontSize;
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Premium Designed Background
            Container(
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
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: -150,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(
                            child: RichText(
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
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      SizedBox(width: 2),

                                      CircleAvatar(
                                        radius: 40,
                                        backgroundColor: theme
                                            .colorScheme
                                            .primary
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
                                      //const SizedBox(height: 8),

                                      //const SizedBox(width: 20),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'NOR MOHAMMED',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: baseFontSize + 4.0,
                                            ),
                                          ),
                                          Text(
                                            'NOR It! Team',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                              fontSize: baseFontSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 2),
                                    ],
                                  ),
                                ],
                              ),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 3.5,
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
                                  _buildSocialButton(
                                    baseFontSize: baseFontSize,
                                    icon: Icons.ios_share_rounded,
                                    label: 'Share',
                                    onTap: _shareApp,
                                  ),
                                  _buildSocialButton(
                                    baseFontSize: baseFontSize,
                                    icon: Icons.email_rounded,
                                    label: 'Email',
                                    onTap: _openEmail,
                                  ),
                                  _buildSocialButton(
                                    baseFontSize: baseFontSize,
                                    icon: Icons.storefront_rounded,
                                    label: 'Play Store',
                                    onTap: _openPlayStore,
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
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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
                                      _formatModelName(model.name),
                                      style: TextStyle(fontSize: baseFontSize),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (GeminiModel? newValue) {
                                  if (newValue != null) {
                                    _updateSettings(selectedModel: newValue);
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
                                  hintStyle: TextStyle(
                                    fontSize: baseFontSize,
                                    color: Colors.white54,
                                  ),
                                  prefixIcon: Icon(Icons.key_rounded, size: 20),
                                  suffixIcon: _settings.geminiApiKey.isNotEmpty
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green.shade400,
                                          size: 20,
                                        )
                                      : null,
                                ),
                                controller: _apiKeyController,
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
                                icon: Icon(
                                  Icons.open_in_new_rounded,
                                  size: baseFontSize,
                                ),
                                label: Text(
                                  'Get API Key',
                                  style: TextStyle(fontSize: baseFontSize),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  foregroundColor: theme.colorScheme.primary,
                                  minimumSize: const Size(double.infinity, 44),
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
                                      min: 6.0,
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
      ),
    );
  }

  /// Formats the enum model name into a human-readable string
  /// Example: 'gemini2_0Flash' -> 'Gemini 2.0 Flash'
  String _formatModelName(String name) {
    // 1. Handle the 'gemini' prefix
    String formatted = name.replaceFirst('gemini', 'Gemini ');

    // 2. Replace underscores with dots (for versions like 2_0)
    formatted = formatted.replaceAll('_', '.');

    // 3. Add space before capital letters (e.g., Flash, Pro, Lite)
    formatted = formatted.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (Match m) => '${m[1]} ${m[2]}',
    );

    // 4. Handle edge cases like 'Flashlite' (lowercase 'l')
    if (formatted.endsWith('lite') && !formatted.endsWith(' Lite')) {
      formatted = formatted.replaceFirst('lite', ' Lite');
    }

    // 5. Handle 'live' in 'Flashlive'
    if (formatted.endsWith('live') && !formatted.endsWith(' Live')) {
      formatted = formatted.replaceFirst('live', ' Live');
    }

    return formatted.trim();
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
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
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
