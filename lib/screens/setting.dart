import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingPage> {
  final _settingBox = Hive.box('settingBox');

  String _dropdownValue = 'Gemini'; // Default value
  double _fontSize = 16.0; // Default font size
  num _diversity = 4;
  String _geminiapikey = '';
  @override
  void initState() {
    super.initState();
    // Load stored settings
    _loadSettings();
  }

  _loadSettings() async {
    setState(() {
      _dropdownValue =
          _settingBox.get('dropdownValue', defaultValue: 'Option 1');
      _fontSize = _settingBox.get('fontSize', defaultValue: 16.0);
      _diversity = _settingBox.get('diverity', defaultValue: 4);
      _settingBox.get('geminiapikey', defaultValue: '');
    });
  }

  _saveSettings() {
    _settingBox.put('dropdownValue', _dropdownValue);
    _settingBox.put('fontSize', _fontSize);
    _settingBox.put('diversity', _diversity);
    _settingBox.put('geminiapikey', _geminiapikey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          //mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Select the LLM that you want to use:"),
            DropdownButton<String>(
              value: _dropdownValue,
              items:
                  ['Gemini API', 'Lemma API', 'Option 3'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _dropdownValue = newValue!;
                  _saveSettings(); // Save the dropdown value
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Update the variable whenever the text changes
                setState(() {
                  _geminiapikey = value;
                  _saveSettings();
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Logic to save or use the API key
                if (_geminiapikey.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('API Key saved: $_geminiapikey')),
                  );
                  _saveSettings();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('API Key cannot be empty')),
                  );
                }
              },
              child: Text('Save API Key'),
            ),
            SizedBox(height: 20),
            Text("Adiust Font Size:"),
            Slider(
              value: _diversity.toDouble(),
              min: 1,
              max: 10,
              divisions: 10,
              label: _diversity.toStringAsFixed(1),
              onChanged: (double value) {
                setState(() {
                  _diversity = value.toInt();
                  _saveSettings(); // Save the font size
                });
              },
            ),
            SizedBox(height: 20),
            Text("Adiust Font Size:"),
            Slider(
              value: _fontSize,
              min: 10.0,
              max: 30.0,
              divisions: 20,
              label: _fontSize.toStringAsFixed(1),
              onChanged: (double value) {
                setState(() {
                  _fontSize = value;
                  _saveSettings(); // Save the font size
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              'Sample Text',
              style: TextStyle(fontSize: _fontSize),
            ),
          ],
        ),
      ),
    );
  }
}
