import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/ChemnorApi.dart';

class ChatWidget extends StatefulWidget {
  final Map<String, dynamic>? compoundData;

  const ChatWidget({Key? key, this.compoundData}) : super(key: key);

  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final List<({Image? image, String? text, bool fromUser})> _generatedContent = <({Image? image, String? text, bool fromUser})>[];
  bool _loading = false;
  ChemnorApi ApiSrv = ChemnorApi();
  @override
  void initState() {
    super.initState();
    _model = ApiSrv.model('AIzaSyCni1xHMgBlzjQWUXj9f-dcyNhpcfRgKUk');
    _chat = _model.startChat();

    // If compoundData is provided, send an initial message to Gemini about the compound
    if (widget.compoundData != null) {
      final compoundInfo = widget.compoundData!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      final initialPrompt =
          "Let's discuss the following chemical compound:\n$compoundInfo\n . "
          "You are an expert chemistry assistant. Answer questions and provide insights about this compound based on its data above.";
      _sendInitialCompoundMessage(initialPrompt);
    }
  }

  String processAIText(String? text) {
    if (text == null) return '';
    // Only replace "you are" (case-insensitive) with "i am"
    return text.replaceAllMapped(RegExp(r'you are', caseSensitive: false), (match) => 'i am');
  }

  Future<void> _sendInitialCompoundMessage(String message) async {
    setState(() {
      _loading = true;
    });

    try {
      _generatedContent.add((image: null, text: message, fromUser: false));
      final response = await _chat.sendMessage(Content.text(message));
      final text = processAIText(response.text);
      if (text != null) {
        _generatedContent.add((image: null, text: processAIText(text), fromUser: false));
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ApiSrv.showError(context, e.toString());
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt...',
      border: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)),
      focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)),
    );
    const String _apiKey = 'AIzaSyCni1xHMgBlzjQWUXj9f-dcyNhpcfRgKUk';
    return Scaffold(
      appBar: AppBar(title: Text(widget.compoundData?['name'] != null ? 'Chat: ${widget.compoundData!['name']}' : 'Chat')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.compoundData != null)
              /*Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.compoundData!.entries.map((entry) => Text('${entry.key}: ${entry.value}')).toList(),
                  ),
                ),
              ),*/
              Expanded(
                child:
                    _apiKey.isNotEmpty
                        ? ListView.builder(
                          controller: _scrollController,
                          itemBuilder: (context, idx) {
                            final content = _generatedContent[idx];
                            return MessageWidget(text: content.text, image: content.image, isFromUser: content.fromUser);
                          },
                          itemCount: _generatedContent.length,
                        )
                        : ListView(
                          children: const [
                            Text(
                              'No API key found. Please provide an API Key using '
                              "'--dart-define' to set the 'API_KEY' declaration.",
                            ),
                          ],
                        ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
              child: Row(
                children: [
                  Expanded(child: TextField(autofocus: true, focusNode: _textFieldFocus, decoration: textFieldDecoration, controller: _textController, onSubmitted: _sendChatMessage)),
                  const SizedBox.square(dimension: 15),
                  IconButton(
                    onPressed:
                        !_loading
                            ? () async {
                              //ApiSrv.sendImagePrompt(_textController.text);
                            }
                            : null,
                    icon: Icon(Icons.image, color: _loading ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary),
                  ),
                  if (!_loading)
                    IconButton(
                      onPressed: () async {
                        _sendChatMessage(_textController.text);
                      },
                      icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                    )
                  else
                    const CircularProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _generatedContent.add((image: null, text: message, fromUser: true));
    });

    try {
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text;
      setState(() {
        _generatedContent.add((image: null, text: processAIText(text ?? 'No response from AI.'), fromUser: false));
        _loading = false;
      });
      // Scroll to bottom after a short delay
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      ApiSrv.showError(context, e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      _textFieldFocus.requestFocus();
    }
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({super.key, this.image, this.text, required this.isFromUser});

  final Image? image;
  final String? text;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: BoxDecoration(color: !isFromUser ? Colors.transparent : Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                if (text case final text?) MarkdownBody(data: text, styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(p: Theme.of(context).textTheme.bodyMedium)),
                if (image case final image?) image,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Chat Page', style: TextStyle(fontSize: 24)));
  }
}
