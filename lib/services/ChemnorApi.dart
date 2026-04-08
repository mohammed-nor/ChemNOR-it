import 'package:chemnor_it/main.dart';
import 'package:flutter/material.dart';
import 'package:chem_nor/chem_nor.dart'; // Use chem_nor package

class ChemnorApi {
  // Singleton pattern to ensure one instance throughout the app
  static final ChemnorApi _instance = ChemnorApi._internal();
  factory ChemnorApi() => _instance;

  // Internal state for the package client
  late ChemNOR _currentClient;

  ChemnorApi._internal() {
    // Initialize with current settings
    _updateClient();

    // Listen for setting changes and update the client instantly
    settingsController.addListener(_updateClient);
  }

  void _updateClient() {
    _currentClient = ChemNOR(
      genAiApiKey: settingsController.value.geminiApiKey,
      model: settingsController.value.selectedModel.apiName,
    );
  }

  /// Manually force a re-initialization of the AI client
  void reinitiate() {
    _updateClient();
  }

  /// Compatibility for legacy code that tries to set apikey directly
  set apikey(String value) {
    if (value != settingsController.value.geminiApiKey) {
      settingsController.updateField(geminiApiKey: value);
    }
  }

  String get apikey => settingsController.value.geminiApiKey;

  Future<String> fetchResponse(String inputText) async {
    final result = await _currentClient.chat(inputText, '');
    return result ?? 'No response from ChemNOR';
  }

  Future<String> chemist(String cid) async {
    final result = await _currentClient.chemist(cid);
    return result ?? 'Analysis failed';
  }

  Future<String> findListOfCompoundsJSN(String description) async {
    // Forward the search request to the package client using the correct method name
    final result = await _currentClient.findListOfCompoundsJSN(description);
    return result ?? '';
  }

  Future<String> findListOfCompoundsJSN_New(String description) async {
    // Forward the search request to the package client using the correct method name
    final result = await _currentClient.findListOfCompoundsJSN(description);
    return result ?? '';
  }

  // Scroll controller used for auto-scrolling chat
  final ScrollController _scrollController = ScrollController();

  void scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  void showError(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong !!'),
          content: SingleChildScrollView(child: SelectableText(message)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
