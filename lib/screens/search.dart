/// A stateful widget that provides a search interface for chemical compounds.
///
/// The [SearchWidget] allows users to enter a prompt describing chemical compounds,
/// sends the prompt to an API, and displays a list of matching compounds with their details.
///
/// Features:
/// - Text input for user prompts.
/// - Asynchronous API call to fetch compounds based on the prompt.
/// - Displays loading indicator while fetching data.
/// - Shows error messages if the API call fails or returns unexpected data.
/// - Presents results as a list of cards, each showing compound information and an image (if available).
/// - Tapping a compound navigates to a chat screen with detailed compound data.
///
/// Dependencies:
/// - Requires [ChemNOR] API service and a valid API key.
/// - Uses [settingsController] for font size and API key configuration.
///
/// Example usage:
/// ```dart
/// SearchWidget()
/// ```
import 'package:chem_nor/chem_nor.dart';
import 'package:chemnor__it/main.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../key.dart';
import '../screens/chat.dart'; // Add this import for navigation
import '../screens/settings_controller.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
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
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> getPublicationCount(String cid) async {
    try {
      final response = await http.get(Uri.parse('https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$cid/xrefs/PubMedID/JSON'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pubmedIds = data['InformationList']['Information'][0]['PubMedID'] as List?;
        return pubmedIds?.length.toString() ?? '0';
      }
    } catch (e) {
      print('Error fetching publication count: $e');
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = settingsController.value.fontSize;
    final apiKey = settingsController.value.geminiApiKey;

    return SafeArea(
      child: Scaffold(
        //appBar: AppBar(title: const Text('Find Compounds')
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: <TextSpan>[
                          TextSpan(text: 'ChemNOR ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22)),
                          TextSpan(text: 'it!', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.redAccent, fontSize: 18)),
                        ],
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(),
                        children: <TextSpan>[
                          TextSpan(text: 'C', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'hemical ', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'H', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'euristic ', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'E', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'valuation of ', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'M', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'olecules ', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'N', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'etworking for ', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'O', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'ptimized ', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'R', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10)),
                          TextSpan(text: 'eactivity', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
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
                        color: Colors.deepPurple.withOpacity(0.1),
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 12.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatWidget(compoundData: compound)));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left side: Image and Scholar info
                                Column(
                                  children: [
                                    Container(
                                      width: 180,
                                      height: 180,
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                                      child:
                                          imageUrl != null
                                              ? OverflowBox(
                                                maxWidth: 290,
                                                maxHeight: 290,
                                                child: Center(
                                                  child: Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    width: 225,
                                                    height: 225,
                                                    errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 60),
                                                  ),
                                                ),
                                              )
                                              : const Icon(Icons.image_not_supported, size: 60),
                                    ),
                                    const SizedBox(height: 8),
                                    // Add below the molecule image
                                    FutureBuilder<String>(
                                      future: getPublicationCount(cid ?? ''),
                                      builder: (context, snapshot) {
                                        return Text('PubMed Citations: ${snapshot.data ?? "Loading..."}', style: TextStyle(fontSize: 13, color: Colors.blueGrey[700]));
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      //icon: const Icon(Icons.open_in_new, size: 18),
                                      label: const Text('Scholar it!'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        textStyle: const TextStyle(fontSize: 13),
                                        minimumSize: const Size(0, 32),
                                      ),
                                      onPressed: () {
                                        final moleculeName = Uri.encodeComponent(compound['name'] ?? '');
                                        final userDesc = Uri.encodeComponent(_searchController.text);
                                        final scholarUrl = 'https://scholar.google.com/scholar?q="$moleculeName"+$userDesc';
                                        // ignore: deprecated_member_use
                                        launchUrl(Uri.parse(scholarUrl));
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                // Right side: Compound details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(compound['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 8),
                                      ...compound.entries
                                          .where((entry) => entry.key != 'name')
                                          .map((entry) => Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Text('${entry.key}: ${entry.value}')))
                                          .toList(),
                                    ],
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
