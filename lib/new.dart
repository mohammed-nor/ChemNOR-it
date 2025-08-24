import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chem_nor/chem_nor.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'JSON Fetch Demo', theme: ThemeData(primarySwatch: Colors.blue), home: JsonFetchScreen());
  }
}

class JsonFetchScreen extends StatefulWidget {
  @override
  _JsonFetchScreenState createState() => _JsonFetchScreenState();
}

class _JsonFetchScreenState extends State<JsonFetchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<List<dynamic>> _dataa = []; // Specify the type as List<List<dynamic>>
  bool _isLoading = false;
  final finder = ChemNOR(genAiApiKey: 'your-api-key');

  Future<void> _fetchData(String query) async {
    setState(() => _isLoading = true);
    _dataa = [];

    try {
      final response = await http.get(Uri.parse('https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$query/JSON'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData != null && jsonData['PC_Compounds'] != null && jsonData['PC_Compounds'].isNotEmpty) {
          setState(() {
            List<dynamic> res = jsonData['PC_Compounds'][0]['props'];
            _dataa.add(res);
            print(_dataa);
            _isLoading = false;
          });
        } else {
          throw Exception('No data found for the given CID');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JSON Fetch Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Enter search query', suffixIcon: Icon(Icons.search))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _fetchData(_controller.text), child: const Text('Search')),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: _dataa.length,
                        itemBuilder: (context, index) {
                          final item = _dataa[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    (item).map((item) {
                                      // Explicit cast here
                                      final label = item['urn']['label'];
                                      final name = item['urn']['name'];
                                      final value = item['value'];
                                      String displayValue = "";

                                      // Handle different data types
                                      switch (item['urn']['datatype']) {
                                        case 1: // String
                                          displayValue = value['sval'] ?? "N/A";
                                          break;
                                        case 5: // Integer
                                          displayValue = value['ival']?.toString() ?? "N/A";
                                          break;
                                        case 7: // Float
                                          displayValue = value['fval']?.toString() ?? "N/A";
                                          break;
                                        case 16: // Binary (Fingerprint)
                                          //displayValue = "Fingerprint data (not displayed)";
                                          displayValue = value['binary']?.toString() ?? "N/A";
                                          ;
                                          break;
                                        default:
                                          displayValue = "Unknown data type";
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text("$label ${name != null ? "$name" : ""}: $displayValue", style: const TextStyle(fontSize: 16.0)),
                                      );
                                    }).toList(),
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
