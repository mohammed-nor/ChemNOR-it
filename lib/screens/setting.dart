/// A settings page that allows users to configure application preferences.
///
/// This page provides the following features:
/// - Select the Large Language Model (LLM) to use from available Gemini models.
/// - Enter and save a Gemini API key.
/// - Display the currently used API key (either the user-provided key or a default key).
/// - Adjust the font size using a slider.

// Import necessary packages
import 'package:chem_nor/chem_nor.dart'; // For GeminiModel enum
import 'package:chemnor__it/key.dart'; // For default API key access
import 'package:chemnor__it/main.dart'; // App configuration
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
class _SettingsPageState extends State<SettingPage> {
  // Store current app settings
  late AppSettings _settings;

  // Define available LLM models as a list
  // This shows all available Gemini models that the app can use
  final List<GeminiModel> llmModels = [GeminiModel.gemini1_5Flash, GeminiModel.gemini2_0Flash, GeminiModel.gemini2_0FlashLite, GeminiModel.gemini2_5Pro, GeminiModel.gemini2_5Flash];

  @override
  // Initialize state when widget is created
  void initState() {
    super.initState();
    // Get current settings from the controller
    _settings = settingsController.value;

    // Safety check: if selected model isn't in our list, use a default
    if (!llmModels.contains(_settings.selectedModel)) {
      _updateSettings(selectedModel: llmModels[1]); // Default to second model
    }
  }

  // Method to update settings via the controller
  void _updateSettings({GeminiModel? selectedModel, double? fontSize, num? diversity, String? geminiApiKey}) {
    // Update settings using the controller
    settingsController.updateField(selectedModel: selectedModel ?? _settings.selectedModel, fontSize: fontSize, diversity: diversity, geminiApiKey: geminiApiKey);

    // Update local state to reflect changes
    setState(() {
      _settings = settingsController.value;
    });
  }

  @override
  // Build the UI for the settings page
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with centered title
      //appBar: AppBar(centerTitle: true, title: const Text("Settings")),

      // Main content
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            Text("TThis app is developed by", style: TextStyle(fontSize: _settings.fontSize, color: Colors.grey.shade500), textAlign: TextAlign.center),
            ClipOval(child: Image.asset('images/1.png', width: 200, height: 200)),

            //clipBehavior: Clip.hardEdge,clipper: ,
            const SizedBox(height: 10),
            Text("NOR MOHAMMED", style: TextStyle(fontSize: _settings.fontSize + 6, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("nour1608@gmail.com", style: TextStyle(fontSize: _settings.fontSize, color: Colors.grey[700])),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                // Define the URL explicitly (it seems 'githubUrl' might be undefined)
                const String githubUrl = "https://github.com/mohammed-nor";

                try {
                  Uri url = Uri.parse(githubUrl);
                  // Use external application to open URLs on mobile
                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication, // Changed from inAppWebView
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot open $githubUrl'), backgroundColor: Colors.red));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              icon: const Icon(Icons.link),
              label: const Text("GitHub"),
            ),
            const SizedBox(height: 40),
            // Model selection section
            const Text("LLM Model that you want to use"),
            // Dropdown for model selection
            DropdownButton<GeminiModel>(
              value: _settings.selectedModel,
              alignment: AlignmentDirectional.center,
              items:
                  llmModels.map((GeminiModel model) {
                    return DropdownMenuItem<GeminiModel>(value: model, child: Text(model.name));
                  }).toList(),
              // Handle model change
              onChanged: (GeminiModel? newValue) {
                if (newValue != null) {
                  // Update settings with new model
                  _updateSettings(selectedModel: newValue);
                  // Save model selection to Hive directly
                  Hive.box('settingBox').put('selectedModel', AppSettings.geminiModelToString(newValue));
                }
              },
            ),

            SizedBox(height: 10),

            // API key input field
            TextField(
              decoration: InputDecoration(labelText: 'Gemini API Key', border: OutlineInputBorder()),
              controller: TextEditingController(text: _settings.geminiApiKey),
              textAlign: TextAlign.center, // Center the input text
              // Update settings when user completes input
              onSubmitted: (value) => _updateSettings(geminiApiKey: value),
            ),

            SizedBox(height: 10),

            // Show the currently used API key (custom or default)
            Text("the used key is ${_settings.geminiApiKey == '' ? gmnkey : _settings.geminiApiKey}", textAlign: TextAlign.center),

            /* Commented out save button - was previously used for API key saving
               Now saving happens on text field submission instead */
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                // Define the URL explicitly (it seems 'githubUrl' might be undefined)
                const String githubUrl = "https://aistudio.google.com/app/api-keys";

                try {
                  Uri url = Uri.parse(githubUrl);
                  // Use external application to open URLs on mobile
                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication, // Changed from inAppWebView
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot open https://aistudio.google.com/app/api-keys'), backgroundColor: Colors.red));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              icon: const Icon(Icons.link),
              label: const Text("Get your API key"),
            ),
            SizedBox(height: 30),

            // Font size adjustment section
            Text("Font Size:"),
            // Slider for font size adjustment
            Slider(
              value: _settings.fontSize,
              min: 10.0,
              max: 30.0,
              divisions: 20,
              label: _settings.fontSize.toStringAsFixed(1),
              // Update font size when slider changes
              onChanged: (double value) => _updateSettings(fontSize: value),
            ),

            SizedBox(height: 20),

            // Commented out sample text that would show current font size
          ],
        ),
      ),
    );
  }
}
