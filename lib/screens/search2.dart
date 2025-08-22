import 'package:chem_nor/chem_nor.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../keys.dart';
import '../screens/chat.dart'; // Add this import for navigation

class SearchWidget2 extends StatefulWidget {
  const SearchWidget2({
    super.key,
  });

  @override
  State<SearchWidget2> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget2> {
  final ApiSrv = ChemNOR(genAiApiKey: gmnkey);

  @override
  initState() {
    _isLoading = false;
    super.initState();
  }

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _compoundsResult = [];
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _searchCompounds(String description) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _compoundsResult = [];
    });

    try {
      final resultsString = await ApiSrv.findListOfCompoundsJSN(description);
      if (resultsString.isEmpty) {
        throw const FormatException("API returned empty or null response");
      }
      final decodedJson = jsonDecode(resultsString);

      // Handle the new response format
      if (decodedJson is Map<String, dynamic> && decodedJson.containsKey('retrieved_compounds')) {
        final compounds = decodedJson['retrieved_compounds'];
        if (compounds is List) {
          setState(() {
            _compoundsResult = compounds.cast<Map<String, dynamic>>();
          });
        } else {
          throw const FormatException("retrieved_compounds is not a list");
        }
      } else if (decodedJson is List) {
        setState(() {
          _compoundsResult = decodedJson.cast<Map<String, dynamic>>();
        });
      } else if (decodedJson is Map<String, dynamic> && decodedJson.containsKey('error')) {
        setState(() {
          _errorMessage = 'Error: ${decodedJson['error']}';
        });
      } else {
        throw const FormatException("API returned an unexpected JSON format");
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
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
        title: const Text('Find Compounds'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Make TextField non-scrollable by wrapping in a Container with no scroll
              Container(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Enter prompt for compounds',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _searchCompounds(_searchController.text);
                        }
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _searchCompounds(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red))
              else if (_compoundsResult.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _compoundsResult.length,
                  itemBuilder: (context, index) {
                    final compound = _compoundsResult[index];
                    final cid = compound['cid']?.toString();
                    final imageUrl = cid != null ? 'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$cid/PNG' : null;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatWidget(
                                compoundData: compound,
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: imageUrl != null
                              ? Image.network(imageUrl, width: 56, height: 56, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported))
                              : const Icon(Icons.image_not_supported),
                          title: Text(compound['name'] ?? 'N/A'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: compound.entries.where((entry) => entry.key != 'name').map((entry) => Text('${entry.key}: ${entry.value}')).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                const Text('Enter a prompt to search for compounds.'),
            ],
          ),
        ),
      ),
    );
  }
}
