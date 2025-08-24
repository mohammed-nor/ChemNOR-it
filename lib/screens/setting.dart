import 'package:chemnor__it/keys.dart';
import 'package:chemnor__it/main.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../screens/settings_controller.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingPage> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = settingsController.value;
  }

  void _updateSettings({String? dropdownValue, double? fontSize, num? diversity, String? geminiApiKey}) {
    settingsController.updateField(dropdownValue: dropdownValue, fontSize: fontSize, diversity: diversity, geminiApiKey: geminiApiKey);
    setState(() {
      _settings = settingsController.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text("Select the LLM that you want to use:"),
            DropdownButton<String>(
              value: _settings.dropdownValue,
              items:
                  ['Gemini API'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) _updateSettings(dropdownValue: newValue);
              },
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(labelText: 'Gemini API Key', border: OutlineInputBorder()),
              controller: TextEditingController(text: _settings.geminiApiKey),
              onChanged: (value) => _updateSettings(geminiApiKey: value),
            ),
            SizedBox(height: 20),
            Text("the used key is ${_settings.geminiApiKey == '' ? gmnkey : _settings.geminiApiKey}", textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_settings.geminiApiKey.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API Key saved: ${_settings.geminiApiKey}')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API Key cannot be empty')));
                }
              },
              child: Text('Save API Key'),
            ),
            SizedBox(height: 20),
            Text("Font Size:"),
            Slider(value: _settings.fontSize, min: 10.0, max: 30.0, divisions: 20, label: _settings.fontSize.toStringAsFixed(1), onChanged: (double value) => _updateSettings(fontSize: value)),
            SizedBox(height: 20),
            //Text('Sample Text', style: TextStyle(fontSize: _settings.fontSize)),
          ],
        ),
      ),
    );
  }
}
