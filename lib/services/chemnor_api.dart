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

  /// Compatibility for legacy code that tries to set apikey directly.
  /// Uses postFrameCallback to guard against being called during a build phase.
  set apikey(String newKey) {
    if (newKey != settingsController.value.geminiApiKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settingsController.updateField(geminiApiKey: newKey);
      });
    }
  }

  String get apikey => settingsController.value.geminiApiKey;

  Future<String> fetchResponse(String inputText) async {
    try {
      final result = await _currentClient.chat(inputText, '');
      return result ?? 'No response from ChemNOR';
    } catch (e) {
      if (e.toString().contains('HttpException') ||
          e.toString().contains('Connection closed')) {
        return 'Network Error: Connection lost while talking to AI. Please check your internet and try again.';
      }
      rethrow;
    }
  }

  Future<String> chemist(String cid) async {
    try {
      final result = await _currentClient.chemist(cid);
      return result ?? 'Analysis failed';
    } catch (e) {
      if (e.toString().contains('HttpException')) {
        return 'Network Error: Failed to fetch compound analysis from PubChem.';
      }
      rethrow;
    }
  }

  Future<String> findListOfCompoundsJSN(String description) async {
    int retries = 2;
    while (retries >= 0) {
      try {
        final result = await _currentClient.findListOfCompoundsJSN(description);
        return result ?? '';
      } catch (e) {
        if (retries == 0 ||
            (!e.toString().contains('HttpException') &&
                !e.toString().contains('Connection closed'))) {
          // If we are out of retries or it's not a network error, rethrow
          rethrow;
        }
        // Wait a bit before retrying
        await Future.delayed(const Duration(milliseconds: 1000));
        retries--;
      }
    }
    return '';
  }

  Future<String> findListOfCompoundsJSNNew(String description) async {
    // Forward the search request to the package client using the correct method name
    final result = await _currentClient.findListOfCompoundsJSN(description);
    return result ?? '';
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
