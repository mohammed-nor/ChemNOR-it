// Here's a full Flutter demo app that:
// Accepts a molecule's IUPAC name.
// Converts it to a SMILES string using the Cactus NIH resolver.
// Sends the SMILES to the IBM RXN Retrosynthesis API.
// Converts SMILES outputs to plain text names.
// Displays each retrosynthesis suggestion in a card.

// ✅ pubspec.yaml Dependencies

// dependencies:
// flutter:
//  sdk: flutter
//  http: ^0.14.0

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(RetroSynthApp());

class RetroSynthApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retrosynthesis Demo',
      home: RetroHomePage(),
    );
  }
}

class RetroHomePage extends StatefulWidget {
  @override
  _RetroHomePageState createState() => _RetroHomePageState();
}

class _RetroHomePageState extends State<RetroHomePage> {
  final _controller = TextEditingController();
  List<String> _suggestions = [];
  bool _loading = false;
  String? _error;

  Future<String> getSmilesFromName(String name) async {
    final url = Uri.parse('https://cactus.nci.nih.gov/chemical/structure/$name/smiles');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return response.body.trim();
    } else {
      throw Exception('SMILES conversion failed');
    }
  }

  Future<String> getChemicalName(String smiles) async {
    final url = Uri.parse('https://cactus.nci.nih.gov/chemical/structure/$smiles/iupac_name');
    final response = await http.get(url);
    return response.statusCode == 200 ? response.body.trim() : smiles;
  }

  Future<List<String>> getRetrosynthesis(String smiles) async {
    final url = Uri.parse('https://rxn.res.ibm.com/rxn/api/api/v1/retrosynthesis');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'smiles': smiles, 'max_steps': 1, 'nbeams': 3}),
    );

    if (response.statusCode != 200) throw Exception("Retrosynthesis failed");

    final data = jsonDecode(response.body);
    final predictions = data['predictions'] as List;
    return predictions.map<String>((rxn) => rxn.toString()).toList();
  }

  Future<List<String>> formatReactions(List<String> rxnSmilesList) async {
    List<String> results = [];
    for (final rxn in rxnSmilesList) {
      final parts = rxn.split('>>');
      if (parts.length != 2) continue;

      final reactants = parts[0].split('.');
      final products = parts[1].split('.');

      final reactantNames = await Future.wait(reactants.map(getChemicalName));
      final productNames = await Future.wait(products.map(getChemicalName));

      results.add('${reactantNames.join(' + ')} → ${productNames.join(' + ')}');
    }
    return results;
  }

  Future<void> runRetrosynthesis() async {
    setState(() {
      _loading = true;
      _error = null;
      _suggestions = [];
    });

    try {
      final iupac = _controller.text.trim();
      final smiles = await getSmilesFromName(iupac);
      final rxnSmiles = await getRetrosynthesis(smiles);
      final formatted = await formatReactions(rxnSmiles);

      setState(() {
        _suggestions = formatted;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Retrosynthesis Tool')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter IUPAC Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : runRetrosynthesis,
              child: Text(_loading ? 'Loading...' : 'Predict Retrosynthesis'),
            ),
            SizedBox(height: 20),
            _error != null
                ? Text('Error: $_error', style: TextStyle(color: Colors.red))
                : Expanded(
                    child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (_, i) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_suggestions[i]),
                        ),
                      ),
                    ),
                  )
          ],
        ),
      ),
    );
  }
}
