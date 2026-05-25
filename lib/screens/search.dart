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
import 'package:hive/hive.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching URLs
import 'package:http/http.dart' as http; // HTTP requests

// Import local files
import '../screens/chat.dart'; // For navigation to chat screen
import '../services/chemnor_api.dart'; // Add this import

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
  final apiSrv = ChemnorApi();

  // Track the current search progress state
  SearchProgress _progress = SearchProgress.idle;

  // Message to display about current progress
  String _progressMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedCompounds();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  // Saved compounds — persisted in Hive
  List<Map<String, dynamic>> _savedCompounds = [];

  // Error message to display if search fails
  String _errorMessage = '';

  // ── Saved compounds persistence ──────────────────────────────────────────

  /// Load saved compounds from Hive on startup
  void _loadSavedCompounds() {
    final box = Hive.box('savedBox');
    final raw = box.get('saved', defaultValue: <dynamic>[]) as List;
    setState(() {
      _savedCompounds = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    });
  }

  /// Persist current saved list to Hive
  void _persistSaved() {
    Hive.box('savedBox').put(
      'saved',
      _savedCompounds.map((c) => Map<String, dynamic>.from(c)).toList(),
    );
  }

  /// Returns true if the compound (by cid) is already saved
  bool _isSaved(Map<String, dynamic> compound) {
    final cid = compound['cid']?.toString();
    if (cid == null) return false;
    return _savedCompounds.any((s) => s['cid']?.toString() == cid);
  }

  /// Toggle save/unsave for a compound
  void _toggleSave(Map<String, dynamic> compound) {
    setState(() {
      if (_isSaved(compound)) {
        _savedCompounds.removeWhere(
          (s) => s['cid']?.toString() == compound['cid']?.toString(),
        );
      } else {
        _savedCompounds.add(Map<String, dynamic>.from(compound));
      }
    });
    _persistSaved();
  }

  /// Show the saved compounds bottom sheet

  // Strips markdown code fences that Gemini sometimes wraps around JSON
  String _sanitizeJson(String raw) {
    // Remove ```json ... ``` or ``` ... ``` wrappers
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true);
    final match = fenced.firstMatch(raw);
    if (match != null) return match.group(1)!.trim();
    return raw.trim();
  }

  // Safely convert a dynamic list element to Map<String, dynamic>
  Map<String, dynamic>? _toStringMap(dynamic e) {
    if (e is Map) {
      try {
        return e.map((k, v) => MapEntry(k.toString(), v));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Main search function - performs the API call and processes results
  Future<void> _searchCompounds(String description) async {
    // Update UI to show loading state and reset previous results
    if (mounted) {
      setState(() {
        _errorMessage = '';
        _compoundsResult = [];
        _progress = SearchProgress.processingPrompt;
        _progressMessage = 'Processing your search query...';
      });
    }

    try {
      // Step 1: Processing prompt - add a small delay for visual feedback
      await Future.delayed(const Duration(milliseconds: 500));

      // Update UI to show next stage
      if (mounted) {
        setState(() {
          _progress = SearchProgress.fetchingCompounds;
          _progressMessage =
              'Fetching compound information...\nUsing ${settingsController.value.selectedModel.apiName} model';
        });
      }

      // Step 2: Fetch compound data from API
      final String rawResult;
      try {
        rawResult = await apiSrv.findListOfCompoundsJSN(description);
      } catch (apiError) {
        throw Exception('API call failed: $apiError');
      }

      // Handle empty response
      if (rawResult.isEmpty) {
        throw const FormatException(
          'The AI returned an empty response. Check your API key in Settings.',
        );
      }

      // Update UI to show processing stage
      if (mounted) {
        setState(() {
          _progress = SearchProgress.processingResults;
          _progressMessage = 'Processing compound data...';
        });
      }

      // Step 3: Sanitise then parse JSON response
      // Gemini sometimes wraps JSON in markdown code fences — strip them first
      final sanitised = _sanitizeJson(rawResult);

      dynamic decodedJson;
      try {
        decodedJson = jsonDecode(sanitised);
      } on FormatException catch (fe) {
        throw FormatException(
          'Could not parse AI response as JSON. '
          'Raw response (first 200 chars): ${rawResult.substring(0, rawResult.length.clamp(0, 200))}\n'
          'Parse error: $fe',
        );
      }

      // Step 4: Process response based on its format
      List<dynamic>? compoundList;

      if (decodedJson is Map<String, dynamic> &&
          decodedJson.containsKey('retrieved_compounds')) {
        // Format 1: { "retrieved_compounds": [...] }
        final compounds = decodedJson['retrieved_compounds'];
        if (compounds is List) {
          compoundList = compounds;
        } else {
          throw const FormatException(
            '"retrieved_compounds" field is not a list.',
          );
        }
      } else if (decodedJson is List) {
        // Format 2: Direct list [...]
        compoundList = decodedJson;
      } else if (decodedJson is Map<String, dynamic> &&
          decodedJson.containsKey('error')) {
        // Format 3: { "error": "..." }
        throw Exception('API error: ${decodedJson['error']}');
      } else {
        throw FormatException(
          'Unexpected JSON structure. Got: ${decodedJson.runtimeType}',
        );
      }

      // Safely convert each element — skip any that are not Maps
      final parsed = compoundList
          .map(_toStringMap)
          .whereType<Map<String, dynamic>>()
          .toList();

      if (parsed.isEmpty) {
        throw const FormatException(
          'No valid compound entries found in the response.',
        );
      }

      if (mounted) {
        setState(() {
          _compoundsResult = parsed;
          _progress = SearchProgress.complete;
          _progressMessage = 'Found ${_compoundsResult.length} compound(s)';
        });
      }
    } catch (e) {
      if (!mounted) return;

      String displayError = e.toString();

      // Clean up common error strings for better user readability
      if (displayError.contains('HttpException') ||
          displayError.contains('Connection closed')) {
        displayError =
            'Network Connection Issue: PubChem or the AI service closed the connection unexpectedly. This can happen due to unstable internet or temporary service limits. Please try your search again in a moment.';
      } else if (displayError.contains('NoSuchMethodError') &&
          displayError.contains('[]')) {
        displayError =
            'Data Processing Error: The AI returned an unexpected response format. Try refining your search query or switching the model in Settings.';
      }

      if (mounted) {
        setState(() {
          _progress = SearchProgress.error;
          _errorMessage = displayError;
        });
      }
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
        final infoList = data['InformationList'];
        if (infoList == null) return '0';
        final information = infoList['Information'];
        if (information == null || (information as List).isEmpty) return '0';

        final firstInfo = information[0];
        if (firstInfo is Map && firstInfo.containsKey('PubMedID')) {
          final pubmedIds = firstInfo['PubMedID'] as List?;
          return pubmedIds?.length.toString() ?? '0';
        }
        return '0';
      }
    } catch (e) {
      // Silent catch or use proper logging
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseFontSize = settingsController.value.fontSize;
    // Get user preferences from settings controller
    final fontSize = settingsController.value.fontSize;
    final apiKey = settingsController.value.geminiApiKey;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Background handled by the Stack
        body: Stack(
          children: [
            // Premium Designed Background
            Container(
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
                        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
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
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0),
                    child: RichText(
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
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        // Search text field
                        TextField(
                          controller: _searchController,
                          style: TextStyle(
                            fontSize: baseFontSize,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Describe compound properties...',
                            hintStyle: TextStyle(
                              fontSize: baseFontSize,
                              color: Colors.white54,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: baseFontSize + 4,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.auto_awesome_rounded,
                                size: baseFontSize + 2,
                              ),
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
                        const SizedBox(height: 16),
                        // ── No API key warning banner ────────────────────────
                        if (apiKey.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No API key configured. '
                                      'Get a free key from Google AI Studio to use ChemNOR.',
                                      style: TextStyle(
                                        color: Colors.amber.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: fontSize - 2,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => launchUrl(
                                      Uri.parse(
                                        'https://aistudio.google.com/app/api-keys',
                                      ),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.amber.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Get Key',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: baseFontSize - 5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // ── Progress / Error / Results ──────────────────────

                        // Active search progress (not idle, not done, not error)
                        if (_progress != SearchProgress.idle &&
                            _progress != SearchProgress.complete &&
                            _progress != SearchProgress.error)
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              LinearProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _progressMessage,
                                style: TextStyle(
                                  color: Colors.grey[200],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
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
                        // Error card — always visible when progress == error
                        else if (_progress == SearchProgress.error)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Search Failed',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: baseFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.red[200],
                                    fontSize: baseFontSize - 2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _progress = SearchProgress.idle;
                                    _errorMessage = '';
                                  }),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Dismiss'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Results display - list of compound cards
                        // Results display - list of compound cards
                        if (_compoundsResult.isNotEmpty)
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
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
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
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
                                          builder: (context) => ChatWidget(
                                            compoundData: compound,
                                            task: _searchController.text,
                                          ),
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
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: imageUrl != null
                                                    ? OverflowBox(
                                                        maxWidth: 187,
                                                        maxHeight: 187,
                                                        child: Image.network(
                                                          imageUrl,
                                                          width: 187,
                                                          height: 187,
                                                          fit: BoxFit.contain,
                                                          errorBuilder:
                                                              (
                                                                c,
                                                                e,
                                                                s,
                                                              ) => const Icon(
                                                                Icons.science,
                                                                size: 40,
                                                              ),
                                                        ),
                                                      )
                                                    : const Icon(
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
                                                        fontSize:
                                                            baseFontSize + 4.0,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Theme(
                                                      data: theme.copyWith(
                                                        textTheme: theme.textTheme.copyWith(
                                                          headlineSmall:
                                                              TextStyle(
                                                                fontSize:
                                                                    baseFontSize +
                                                                    2,
                                                              ),
                                                          titleLarge: TextStyle(
                                                            fontSize:
                                                                baseFontSize +
                                                                1,
                                                          ),
                                                          titleMedium: TextStyle(
                                                            fontSize:
                                                                baseFontSize,
                                                          ),
                                                        ),
                                                      ),
                                                      child: GptMarkdown(
                                                        'ID: ${compound['cid'] ?? 'N/A'}',
                                                        style: TextStyle(
                                                          fontSize:
                                                              baseFontSize -
                                                              2.0,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    FutureBuilder<String>(
                                                      future:
                                                          getPublicationCount(
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
                                                            color:
                                                                const Color(
                                                                  0xFF6366F1,
                                                                ).withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  const Color(
                                                                    0xFF6366F1,
                                                                  ).withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .article_outlined,
                                                                size: 14,
                                                                color:
                                                                    const Color(
                                                                      0xFF6366F1,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                '${snapshot.data ?? "..."} Citations',
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      baseFontSize -
                                                                      3.0,
                                                                  color: const Color(
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
                                                          .withValues(
                                                            alpha: 0.05,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${e.key}: ${e.value}',
                                                      style: TextStyle(
                                                        fontSize:
                                                            baseFontSize - 2.0,
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
                                                          compound['name'] ??
                                                              '',
                                                        );
                                                    final userDesc =
                                                        Uri.encodeComponent(
                                                          _searchController
                                                              .text,
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
                                                  label: Text('Scholar search'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF6366F1,
                                                            ),
                                                        minimumSize: const Size(
                                                          double.infinity,
                                                          40,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Save / bookmark toggle
                                              IconButton.filledTonal(
                                                onPressed: () =>
                                                    _toggleSave(compound),
                                                style: IconButton.styleFrom(
                                                  backgroundColor:
                                                      _isSaved(compound)
                                                      ? const Color(0xFF6366F1)
                                                      : Colors.white.withValues(
                                                          alpha: 0.07,
                                                        ),
                                                ),
                                                icon: Icon(
                                                  _isSaved(compound)
                                                      ? Icons.bookmark_rounded
                                                      : Icons
                                                            .bookmark_border_rounded,
                                                  size: 20,
                                                  color: _isSaved(compound)
                                                      ? Colors.white
                                                      : Colors.white54,
                                                ),
                                                tooltip: _isSaved(compound)
                                                    ? 'Remove from saved'
                                                    : 'Save compound',
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
                          ),

                        // ── Saved Compounds Section ─────────────────────────
                        if (_savedCompounds.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              const Icon(
                                Icons.bookmark_rounded,
                                color: Color(0xFF6366F1),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Saved Compounds (${_savedCompounds.length})',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: baseFontSize + 2.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(bottom: 40),
                            itemCount: _savedCompounds.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final c = _savedCompounds[i];
                              final cid = c['cid']?.toString();
                              return Material(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatWidget(
                                          compoundData: c,
                                          task: _searchController.text,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        // Molecule thumbnail
                                        Container(
                                          width: 60,
                                          height: 60,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: cid != null
                                              ? OverflowBox(
                                                  maxWidth: 100,
                                                  maxHeight: 100,
                                                  child: Image.network(
                                                    'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$cid/PNG',
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.contain,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            const Icon(
                                                              Icons.science,
                                                              size: 32,
                                                            ),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.science,
                                                  size: 32,
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Name & CID
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                c['name'] ?? 'Unknown',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: baseFontSize,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (cid != null)
                                                Text(
                                                  'CID: $cid',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.4),
                                                    fontSize: baseFontSize - 4,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Remove button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.bookmark_remove_rounded,
                                            color: Colors.redAccent,
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _savedCompounds.removeAt(i);
                                            });
                                            _persistSaved();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
