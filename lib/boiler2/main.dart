import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  //runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compound Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CompoundSearchScreen(),
    );
  }
}

class CompoundSearchScreen extends StatefulWidget {
  @override
  _CompoundSearchScreenState createState() => _CompoundSearchScreenState();
}

class _CompoundSearchScreenState extends State<CompoundSearchScreen> {
  final TextEditingController _promptController = TextEditingController();
  List<Map<String, dynamic>> _similarCompounds = [];
  bool _isLoading = false;

  Future<String?> _generateSmilesFromPrompt(String prompt) async {
    // Replace with your Gemini API endpoint and API key
    const geminiApiKey = 'AIzaSyCR80a7Gb4kSGd5rX9ingZhJKSw9b9hQgQ';
    const geminiApiUrl = 'https://api.gemini.com/v1/generate';

    final responsee = await http.post(
      Uri.parse(geminiApiUrl),
      headers: {
        'Authorization': 'Bearer $geminiApiKey',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'prompt': prompt}),
    );
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: geminiApiKey,
    );

    final response = await model.generateContent([Content.text(prompt)]);

    return response.text;
  }

  Future<void> _fetchSimilarCompounds(String smiles) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // PubChem API for substructure search
      final response = await http.get(
        Uri.parse(
            'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/substructure/smiles/${Uri.encodeComponent(smiles)}/JSON?MaxRecords=10'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final compounds = data['PC_Compounds'] as List;

        setState(() {
          _similarCompounds = compounds.map((compound) {
            final properties = compound['props'];
            return {
              'cid': compound['id']['id']['cid'],
              'iupacName': properties.firstWhere(
                      (prop) => prop['urn']['label'] == 'IUPAC Name')['value']
                  ['sval'],
              'molecularFormula': properties.firstWhere((prop) =>
                  prop['urn']['label'] == 'Molecular Formula')['value']['sval'],
              'molecularWeight': properties.firstWhere((prop) =>
                  prop['urn']['label'] == 'Molecular Weight')['value']['fval'],
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to fetch similar compounds: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compound Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: 'Enter compound description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final prompt = _promptController.text;
                if (prompt.isNotEmpty) {
                  try {
                    final smiles = await _generateSmilesFromPrompt(prompt);
                    await _fetchSimilarCompounds(smiles!);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text('Search'),
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _similarCompounds.length,
                      itemBuilder: (context, index) {
                        final compound = _similarCompounds[index];
                        return Card(
                          child: ListTile(
                            title: Text(compound['iupacName']),
                            subtitle: Text(
                              'CID: ${compound['cid']}\n'
                              'Formula: ${compound['molecularFormula']}\n'
                              'Weight: ${compound['molecularWeight']}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
