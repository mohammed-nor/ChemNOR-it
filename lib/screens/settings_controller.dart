import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AppSettings {
  String dropdownValue;
  double fontSize;
  num diversity;
  String geminiApiKey;

  AppSettings({required this.dropdownValue, required this.fontSize, required this.diversity, required this.geminiApiKey});

  factory AppSettings.fromHive(Box box) {
    return AppSettings(
      dropdownValue: box.get('dropdownValue', defaultValue: 'Gemini API'),
      fontSize: box.get('fontSize', defaultValue: 16.0),
      diversity: box.get('diversity', defaultValue: 4),
      geminiApiKey: box.get('geminiapikey', defaultValue: ''),
    );
  }

  void saveToHive(Box box) {
    box.put('dropdownValue', dropdownValue);
    box.put('fontSize', fontSize);
    box.put('diversity', diversity);
    box.put('geminiapikey', geminiApiKey);
  }
}

class SettingsController extends ValueNotifier<AppSettings> {
  final Box _box;

  SettingsController(this._box) : super(AppSettings.fromHive(_box));

  void update(AppSettings newSettings) {
    value = newSettings;
    value.saveToHive(_box);
    notifyListeners();
  }

  void updateField({String? dropdownValue, double? fontSize, num? diversity, String? geminiApiKey}) {
    value = AppSettings(
      dropdownValue: dropdownValue ?? value.dropdownValue,
      fontSize: fontSize ?? value.fontSize,
      diversity: diversity ?? value.diversity,
      geminiApiKey: geminiApiKey ?? value.geminiApiKey,
    );
    value.saveToHive(_box);
    notifyListeners();
  }
}
