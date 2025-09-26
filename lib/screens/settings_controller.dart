/// Settings controller for the ChemNOR application.
///
/// Manages application settings using Hive storage and ValueNotifier pattern.
/// Provides both a data model (AppSettings) and a controller (SettingsController)
/// to manage and access settings throughout the app.

import 'package:chem_nor/chem_nor.dart'; // Import for GeminiModel enum
import 'package:flutter/material.dart'; // For ValueNotifier and other Flutter components
import 'package:hive/hive.dart'; // For persistent storage

/// Data class that holds all application settings
class AppSettings {
  GeminiModel selectedModel; // The selected AI model to use
  double fontSize; // Font size for text display
  num diversity; // Diversity parameter for AI responses
  String geminiApiKey; // User's Gemini API key

  /// Default constructor with default values for all settings
  AppSettings({
    this.selectedModel = GeminiModel.gemini1_5Flash, // Default to Gemini 1.5 Flash model
    this.fontSize = 16.0, // Default font size
    this.diversity = 0.5, // Default diversity
    this.geminiApiKey = '', // Empty API key by default
  });

  /// Constructor that loads settings from Hive storage
  /// This handles type conversion and provides defaults when values aren't found
  AppSettings.fromHive(Box box)
    : selectedModel = _stringToGeminiModel(box.get('selectedModel') as String?),
      fontSize = (box.get('fontSize') as num?)?.toDouble() ?? 16.0,
      diversity = (box.get('diversity') as num?) ?? 0.5,
      geminiApiKey = (box.get('geminiapikey') as String?) ?? '';

  /// Helper method to convert string representation to GeminiModel enum
  /// This is needed because Hive can store strings but not enum values directly
  static GeminiModel _stringToGeminiModel(String? modelString) {
    switch (modelString) {
      case 'gemini1_5flash':
        return GeminiModel.gemini1_5Flash;
      case 'gemini2_0flash':
        return GeminiModel.gemini2_0Flash;
      case 'gemini2_0flashlite':
        return GeminiModel.gemini2_0FlashLite;
      case 'gemini2_5pro':
        return GeminiModel.gemini2_5Pro;
      case 'gemini2_5flash':
        return GeminiModel.gemini2_5Flash;
      default:
        return GeminiModel.gemini1_5Flash; // Default if string doesn't match
    }
  }

  /// Helper method to convert GeminiModel enum to string for storage
  static String geminiModelToString(GeminiModel model) {
    // Extract the name part and convert to lowercase
    return model.toString().split('.').last.toLowerCase();
  }

  /// Saves all settings to Hive storage
  void saveToHive(Box box) {
    // Convert model enum to string for storage
    box.put('selectedModel', AppSettings.geminiModelToString(selectedModel));
    box.put('fontSize', fontSize);
    box.put('diversity', diversity);
    box.put('geminiapikey', geminiApiKey);
  }
}

/// Controller class for managing app settings
/// Uses ValueNotifier to notify listeners when settings change
class SettingsController extends ValueNotifier<AppSettings> {
  final Box _box; // Reference to Hive storage box

  /// Constructor initializes with settings from Hive
  SettingsController(this._box) : super(AppSettings.fromHive(_box));

  /// Replace all settings at once
  void update(AppSettings newSettings) {
    value = newSettings; // Update the value
    value.saveToHive(_box); // Save to storage
    notifyListeners(); // Notify listeners about the change
  }

  /// Update specific settings fields, keeping others unchanged
  /// This provides a convenient way to change just one setting
  void updateField({GeminiModel? selectedModel, double? fontSize, num? diversity, String? geminiApiKey}) {
    // Create new settings object with updated fields
    value = AppSettings(
      selectedModel: selectedModel ?? value.selectedModel,
      fontSize: fontSize ?? value.fontSize,
      diversity: diversity ?? value.diversity,
      geminiApiKey: geminiApiKey ?? value.geminiApiKey,
    );
    value.saveToHive(_box); // Save to storage
    notifyListeners(); // Notify listeners about the change
  }
}
