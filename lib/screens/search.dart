/// A stateful widget that provides a search interface for chemical compounds.
///
/// The [SearchWidget] allows users to enter a prompt describing chemical compounds,
/// sends the prompt to an API, and displays a list of matching compounds with their details.
///
/// This file implements the main search functionality for the ChemNOR app.

// Import necessary packages for functionality
import 'package:chem_nor/chem_nor.dart'; // Core ChemNOR functionality
import 'package:chemnor__it/main.dart'; // Main app configuration
import 'dart:convert'; // For JSON processing
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:url_launcher/url_launcher.dart'; // For launching URLs
import 'package:http/http.dart' as http; // HTTP requests
import 'package:hive/hive.dart'; // Local storage

// Import local files
import '../key.dart'; // API key management
import '../screens/chat.dart'; // For navigation to chat screen
import '../screens/settings_controller.dart'; // App settings

// Enum defining the possible states of the search process
enum SearchProgress {
  idle, // Initial state, no search in progress
  processingPrompt, // Processing user's search query
  fetchingCompounds, // Retrieving compound data from API
  processingResults, // Processing API response data
  complete, // Search completed successfully
  error, // Error occurred during search
}

// Main widget class for the search screen
class SearchWidget extends StatefulWidget {
  // Constructor with key parameter for widget identification
  const SearchWidget({super.key});

  @override
  // Create the state for this widget
  State<SearchWidget> createState() => _SearchWidgetState();
}

// State class for the SearchWidget
class _SearchWidgetState extends State<SearchWidget> {
  // Initialize ChemNOR API service with the global API key
  ChemNOR ApiSrv = ChemNOR(genAiApiKey: gmnkey);

  // Track the current search progress state
  SearchProgress _progress = SearchProgress.idle;

  // Message to display about current progress
  String _progressMessage = '';

  @override
  // Initialize state when widget is created
  initState() {
    // Set loading state to false initially
    _isLoading = false;
    super.initState();
  }

  @override
  // Called when inherited widgets change or when settings are updated
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the latest key and model from Hive storage
    final currentKey = (Hive.box('settingBox').get('geminiapikey') as String?) ?? '';
    final currentModel = (Hive.box('settingBox').get('selectedModel') as String?) ?? 'gemini1_5flash';

    // Only recreate API service if key or model has changed
    if (ApiSrv.genAiApiKey != currentKey || ApiSrv.model != currentModel) {
      ApiSrv = ChemNOR(genAiApiKey: currentKey, model: GeminiModel.fromString(currentModel));
    }
  }

  // Controller for the search text field
  final TextEditingController _searchController = TextEditingController();

  // List to store search results
  List<Map<String, dynamic>> _compoundsResult = [];

  // Flag to track loading state
  bool _isLoading = false;

  // Error message to display if search fails
  String _errorMessage = '';

  // Main search function - performs the API call and processes results
  Future<void> _searchCompounds(String description) async {
    // Update UI to show loading state and reset previous results
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _compoundsResult = [];
      _progress = SearchProgress.processingPrompt;
      _progressMessage = 'Processing your search query...';
    });

    try {
      // Step 1: Processing prompt - add a small delay for visual feedback
      await Future.delayed(const Duration(milliseconds: 500));

      // Update UI to show next stage
      setState(() {
        _progress = SearchProgress.fetchingCompounds;
        _progressMessage = 'Fetching compound information...';
      });

      // Step 2: Fetch compound data from API
      final resultsString = await ApiSrv.findListOfCompoundsJSN(description);

      // Handle empty response
      if (resultsString.isEmpty) {
        throw const FormatException("API returned empty or null response");
      }

      // Update UI to show processing stage
      setState(() {
        _progress = SearchProgress.processingResults;
        _progressMessage = 'Processing compound data...';
      });

      // Step 3: Parse JSON response
      final decodedJson = jsonDecode(resultsString);

      // Process response based on its format (handle different response structures)
      if (decodedJson is Map<String, dynamic> && decodedJson.containsKey('retrieved_compounds')) {
        // Format 1: Results in 'retrieved_compounds' field
        final compounds = decodedJson['retrieved_compounds'];
        if (compounds is List) {
          // Update UI with results
          setState(() {
            _compoundsResult = compounds.cast<Map<String, dynamic>>();
            _progress = SearchProgress.complete;
            _progressMessage = 'Found ${_compoundsResult.length} compounds';
          });
        } else {
          throw const FormatException("retrieved_compounds is not a list");
        }
      } else if (decodedJson is List) {
        // Format 2: Results as direct list
        setState(() {
          _compoundsResult = decodedJson.cast<Map<String, dynamic>>();
          _progress = SearchProgress.complete;
          _progressMessage = 'Found ${_compoundsResult.length} compounds';
        });
      } else if (decodedJson is Map<String, dynamic> && decodedJson.containsKey('error')) {
        // Format 3: Error message in response
        setState(() {
          _progress = SearchProgress.error;
          _errorMessage = 'Error: ${decodedJson['error']}';
        });
      } else {
        // Unknown format
        throw const FormatException("API returned an unexpected JSON format");
      }
    } catch (e) {
      // Handle any exceptions that occur during the search process
      if (!mounted) return; // Prevent updating state if widget is no longer in tree
      setState(() {
        _progress = SearchProgress.error;
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      // Update loading state when done (success or error)
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch publication count for a compound from PubMed
  Future<String> getPublicationCount(String cid) async {
    try {
      // Call PubChem API to get PubMed IDs for this compound
      final response = await http.get(Uri.parse('https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$cid/xrefs/PubMedID/JSON'));

      if (response.statusCode == 200) {
        // Parse response to count publications
        final data = jsonDecode(response.body);
        final pubmedIds = data['InformationList']['Information'][0]['PubMedID'] as List?;
        return pubmedIds?.length.toString() ?? '0';
      }
    } catch (e) {
      print('Error fetching publication count: $e');
    }
    return 'N/A'; // Default value if fetch fails
  }

  // Helper method to get appropriate icon for each progress state
  IconData _getProgressIcon(SearchProgress progress) {
    switch (progress) {
      case SearchProgress.processingPrompt:
        return Icons.text_fields; // Text processing icon
      case SearchProgress.fetchingCompounds:
        return Icons.science; // Science/lab icon for data retrieval
      case SearchProgress.processingResults:
        return Icons.analytics; // Analytics icon for data processing
      default:
        return Icons.hourglass_empty; // Default hourglass icon
    }
  }

  // Helper method to get descriptive text for each progress state
  String _getProgressStep(SearchProgress progress) {
    switch (progress) {
      case SearchProgress.processingPrompt:
        return 'Step 1/3: Processing Query';
      case SearchProgress.fetchingCompounds:
        return 'Step 2/3: Fetching Compounds';
      case SearchProgress.processingResults:
        return 'Step 3/3: Processing Results';
      default:
        return '';
    }
  }

  @override
  // Build the UI for the search widget
  Widget build(BuildContext context) {
    // Get user preferences from settings controller
    final fontSize = settingsController.value.fontSize;
    final apiKey = settingsController.value.geminiApiKey;

    return SafeArea(
      child: Scaffold(
        // Main UI structure
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // App title and logo section
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ChemNOR logo text with styling
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: <TextSpan>[
                          TextSpan(text: 'ChemNOR ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22)),
                          TextSpan(text: 'it!', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.redAccent, fontSize: 18)),
                        ],
                      ),
                    ),
                    // ChemNOR acronym explanation
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(),
                        children: <TextSpan>[
                          // Each letter of ChemNOR is highlighted with its meaning
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
                    const SizedBox(height: 10),
                  ],
                ),

                // Search text field
                Container(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Enter prompt for compounds',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          // Trigger search when button is clicked
                          if (_searchController.text.isNotEmpty) {
                            _searchCompounds(_searchController.text);
                          }
                        },
                      ),
                    ),
                    onSubmitted: (value) {
                      // Also trigger search when Enter key is pressed
                      if (value.isNotEmpty) {
                        _searchCompounds(value);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Progress indicator section - shown during active search
                if (_progress != SearchProgress.idle && _progress != SearchProgress.complete)
                  Column(
                    children: [
                      // Progress bar
                      LinearProgressIndicator(
                        value: _progress == SearchProgress.error ? 1.0 : null,
                        valueColor: AlwaysStoppedAnimation<Color>(_progress == SearchProgress.error ? Colors.red : Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      // Progress message
                      Text(_progressMessage, style: TextStyle(color: _progress == SearchProgress.error ? Colors.red : Colors.grey[200], fontStyle: FontStyle.italic)),
                      // Step indicator with icon (if not in error state)
                      if (_progress != SearchProgress.error)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_getProgressIcon(_progress), size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 8),
                              Text(_getProgressStep(_progress), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  )
                // Error message display
                else if (_errorMessage.isNotEmpty)
                  Text(_errorMessage, style: const TextStyle(color: Colors.red))
                // Results display - list of compound cards
                else if (_compoundsResult.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _compoundsResult.length,
                    itemBuilder: (context, index) {
                      final compound = _compoundsResult[index];
                      final cid = compound['cid']?.toString();
                      // Get image URL from PubChem using compound ID
                      final imageUrl = cid != null ? 'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$cid/PNG' : null;

                      // Create card for each compound
                      return Card(
                        color: Colors.deepPurple.withOpacity(0.1),
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 12.0),
                        child: InkWell(
                          // Navigate to chat screen with compound data when tapped
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatWidget(compoundData: compound)));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left side: Image and publication info
                                Column(
                                  children: [
                                    // Compound molecular structure image
                                    Container(
                                      width: 180,
                                      height: 180,
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                                      child:
                                          imageUrl != null
                                              ? OverflowBox(
                                                // Make image larger than container to enable cropping
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

                                    // Publication count from PubMed
                                    FutureBuilder<String>(
                                      future: getPublicationCount(cid ?? ''),
                                      builder: (context, snapshot) {
                                        return Text('PubMed Citations: ${snapshot.data ?? "Loading..."}', style: TextStyle(fontSize: 13, color: Colors.blueGrey[700]));
                                      },
                                    ),

                                    // Button to search Google Scholar
                                    ElevatedButton.icon(
                                      label: const Text('Scholar it!'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        textStyle: const TextStyle(fontSize: 13),
                                        minimumSize: const Size(0, 32),
                                      ),
                                      onPressed: () {
                                        // Construct URL with compound name and user's search query
                                        final moleculeName = Uri.encodeComponent(compound['name'] ?? '');
                                        final userDesc = Uri.encodeComponent(_searchController.text);
                                        final scholarUrl = 'https://scholar.google.com/scholar?q="$moleculeName"+$userDesc';
                                        // Launch Google Scholar search
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
                                      // Compound name with emphasis
                                      Text(compound['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 8),

                                      // Display all compound properties except name (already shown)
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
                // Empty state - no results yet
                else
                  const Text(''),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
