import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive/hive.dart';

class ChemnorApi {
  late String apikey;

  void initiate(String api) {
    apikey = api;
  }

  void startchat(api) {}

  void startsearch(api) {}

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  late Box<String> _settingsBox;
  late final BuildContext context;
  late bool _loading;
  late final GenerativeModel gemini;

  GenerativeModel model(String apikey) {
    return GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apikey);
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
    final gemini = Gemini.instance;
    final value = await gemini.text(inputText);
    return value?.output ?? 'No response';
  }

  void scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  void showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong !!'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}
