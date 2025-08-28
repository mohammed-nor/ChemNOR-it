import 'package:chemnor__it/key.dart';
import 'package:flutter/material.dart';
import 'package:chem_nor/chem_nor.dart'; // Use chem_nor package
import 'package:hive/hive.dart';

class ChemnorApi {
  String apikey = gmnkey;
  late final ChemNOR chemnor = ChemNOR(genAiApiKey: apikey);

  void initiate(String api) {
    apikey = api;
    // Re-initialize chemnor with new API key if needed
    // chemnor = ChemNOR(genAiApiKey: apikey);
  }

  void startchat(api) {}

  void startsearch(api) {}

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  late Box<String> _settingsBox;
  late final BuildContext context;
  late bool _loading;

  // Use chemnor for model-like functionality
  ChemNOR model(String apikey) {
    return ChemNOR(genAiApiKey: apikey);
  }

  Future<void> initHive() async {
    _settingsBox = await Hive.openBox<String>('settings');
    await Hive.openBox('chatMessagesBox');
  }

  Future<String> getApiKey() async {
    _settingsBox = await Hive.openBox<String>('settings');
    return _settingsBox.get('api_key').toString();
  }

  Future<void> setApiKey(String apiKey) async {
    _settingsBox = await Hive.openBox<String>('settings');
    return await _settingsBox.put('api_key', apiKey);
  }

  Future<String> fetchResponse(String inputText) async {
    // Use chemnor's chat method instead of Gemini
    final value = await chemnor.chemist(inputText);
    return value ?? 'No response';
  }

  // Example chemist method for chemistry actions
  Future<String> chemist(String cid) async {
    // You can implement this method using chemnor's API as needed
    final result = await chemnor.chemist(cid);
    return result ?? 'No chemist result';
  }

  void scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 750), curve: Curves.easeOutCirc),
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
