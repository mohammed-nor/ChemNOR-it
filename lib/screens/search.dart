/// A stateful widget that provides a search interface for chemical compounds.
///
/// The [SearchWidget] allows users to enter a prompt describing chemical compounds,
/// sends the prompt to an API, and displays a list of matching compounds with their details.
///
/// This file implements the main search functionality for the ChemNOR app.
library;

// Import necessary packages for functionality
import 'package:chemnor_it/main.dart'; // Main app configuration
import 'dart:convert'; // For JSON processing
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:url_launcher/url_launcher.dart'; // For launching URLs
import 'package:http/http.dart' as http; // HTTP requests

// Import local files
import '../screens/chat.dart'; // For navigation to chat screen
import '../services/ChemnorApi.dart'; // Add this import

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
class _SearchWidgetState extends State<SearchWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ApiSrv = ChemnorApi();

  // Track the current search progress state
  SearchProgress _progress = SearchProgress.idle;

  // Message to display about current progress
  String _progressMessage = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ChemnorApi now handles model and key updates automatically
  }

  // Controller for the search text field
  final TextEditingController _searchController = TextEditingController();

  // List to store search results
  List<Map<String, dynamic>> _compoundsResult = [];

  // Error message to display if search fails
  String _errorMessage = '';

  // Main search function - performs the API call and processes results
  Future<void> _searchCompounds(String description) async {
    // Update UI to show loading state and reset previous results
    setState(() {
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
        _progressMessage =
            'Fetching compound information... \n using ${settingsController.value.selectedModel.apiName} model \n with the key ${settingsController.value.geminiApiKey.isEmpty ? "" : "configured"}';
      });

      // Step 2: Fetch compound data from API
      final resultsString = await ApiSrv.findListOfCompoundsJSN(description);

      // Handle empty response
      try {
        if (resultsString.isEmpty) {
          throw const FormatException("API returned empty or null response");
        }

        // Update UI to show processing stage
        setState(() {
          _progress = SearchProgress.processingResults;
          _progressMessage = 'Processing compound data...';
        });
      } catch (e) {
        _progressMessage = 'Error: ${e.toString()}';
      }

      // Step 3: Parse JSON response
      final decodedJson = jsonDecode(resultsString);

      // Process response based on its format (handle different response structures)
      if (decodedJson is Map<String, dynamic> &&
          decodedJson.containsKey('retrieved_compounds')) {
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
      } else if (decodedJson is Map<String, dynamic> &&
          decodedJson.containsKey('error')) {
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
      if (!mounted) {
        return; // Prevent updating state if widget is no longer in tree
      }
      setState(() {
        _progress = SearchProgress.error;
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      // Update loading state when done (success or error)
      if (!mounted) return;
      setState(() {});
    }
  }

  // Fetch publication count for a compound from PubMed
  Future<String> getPublicationCount(String cid) async {
    try {
      // Call PubChem API to get PubMed IDs for this compound
      final response = await http.get(
        Uri.parse(
          'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$cid/xrefs/PubMedID/JSON',
        ),
      );

      if (response.statusCode == 200) {
        // Parse response to count publications
        final data = jsonDecode(response.body);
        final pubmedIds =
            data['InformationList']['Information'][0]['PubMedID'] as List?;
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
    final baseFontSize = settingsController.value.fontSize;
    // Get user preferences from settings controller
    final fontSize = settingsController.value.fontSize;
    final apiKey = settingsController.value.geminiApiKey;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by the Stack
      body: Stack(
        children: [
          // Premium Designed Background
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF020617)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Subtle glowing orbs for depth
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: -150,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4F46E5).withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'ChemNOR ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: baseFontSize + 4.0,
                          ),
                        ),
                        TextSpan(
                          text: 'it! ',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.redAccent,
                            fontSize: baseFontSize,
                          ),
                        ),
                        TextSpan(
                          text: 'Explore\n',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: baseFontSize,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        TextSpan(
                          text: 'C',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'hemical ',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'H',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'euristic ',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'E',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'valuation of ',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'M',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'olecules ',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'N',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'etworking for ',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'O',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'ptimized ',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'R',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                        TextSpan(
                          text: 'eactivity',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: baseFontSize - 7.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Search text field
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Describe compound properties...',
                          prefixIcon: Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.auto_awesome_rounded),
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
                      const SizedBox(height: 24),

                      // Progress indicator section - shown during active search
                      if (_progress != SearchProgress.idle &&
                          _progress != SearchProgress.complete)
                        Column(
                          children: [
                            // Progress bar
                            LinearProgressIndicator(
                              value: _progress == SearchProgress.error
                                  ? 1.0
                                  : null,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _progress == SearchProgress.error
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Progress message
                            Text(
                              _progressMessage,
                              style: TextStyle(
                                color: _progress == SearchProgress.error
                                    ? Colors.red
                                    : Colors.grey[200],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            // Step indicator with icon (if not in error state)
                            if (_progress != SearchProgress.error)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getProgressIcon(_progress),
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getProgressStep(_progress),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: baseFontSize - 2.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                      // Error message display
                      else if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        )
                      // Results display - list of compound cards
                      else if (_compoundsResult.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _compoundsResult.length,
                          itemBuilder: (context, index) {
                            final compound = _compoundsResult[index];
                            final cid = compound['cid']?.toString();
                            final imageUrl = cid != null
                                ? 'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$cid/PNG'
                                : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Card(
                                margin: EdgeInsets.zero,
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ChatWidget(compoundData: compound),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Image Section
                                            Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: imageUrl != null
                                                  ? Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (c, e, s) =>
                                                          Icon(
                                                            Icons.science,
                                                            size: 40,
                                                          ),
                                                    )
                                                  : Icon(
                                                      Icons.science,
                                                      size: 40,
                                                    ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Title & Basic Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    compound['name'] ??
                                                        'Unknown Compound',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: baseFontSize + 4.0,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'ID: ${compound['cid'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.5),
                                                      fontSize: baseFontSize - 2.0,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  FutureBuilder<String>(
                                                    future: getPublicationCount(
                                                      cid ?? '',
                                                    ),
                                                    builder: (context, snapshot) {
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF6366F1,
                                                          ).withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          border: Border.all(
                                                            color: const Color(
                                                              0xFF6366F1,
                                                            ).withOpacity(0.3),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .article_outlined,
                                                              size: 14,
                                                              color: Color(
                                                                0xFF6366F1,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              '${snapshot.data ?? "..."} Citations',
                                                              style: TextStyle(
                                                                fontSize: baseFontSize - 3.0,
                                                                color: Color(
                                                                  0xFF818CF8,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Properties Grid/List
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: compound.entries
                                              .where(
                                                (e) =>
                                                    e.key != 'name' &&
                                                    e.key != 'cid',
                                              )
                                              .map(
                                                (e) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.05),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${e.key}: ${e.value}',
                                                    style: TextStyle(
                                                      fontSize: baseFontSize - 2.0,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                        const SizedBox(height: 16),
                                        // Action Bar
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  final moleculeName =
                                                      Uri.encodeComponent(
                                                        compound['name'] ?? '',
                                                      );
                                                  final userDesc =
                                                      Uri.encodeComponent(
                                                        _searchController.text,
                                                      );
                                                  final scholarUrl =
                                                      'https://scholar.google.com/scholar?q="$moleculeName"+$userDesc';
                                                  launchUrl(
                                                    Uri.parse(scholarUrl),
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.school_rounded,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  'Scholar search',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF6366F1,
                                                  ),
                                                  minimumSize: const Size(
                                                    double.infinity,
                                                    40,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            IconButton.filledTonal(
                                              onPressed:
                                                  () {}, // Potential for more actions
                                              icon: Icon(
                                                Icons.share_rounded,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      // Empty state - no results yet
                      else
                        Text(''),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
