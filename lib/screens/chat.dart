/// A chat widget for interacting with a chemistry assistant AI about a specific chemical compound.
///
/// If [compoundData] is provided, the chat initializes with context about the compound,
/// allowing the user to ask questions and receive insights from the AI.
///
/// Features:
/// - Displays chat history with user and AI messages.
/// - Allows sending new prompts and receives AI responses.
/// - Chemistry-specific actions via the science icon (calls chemist method).
/// - AI responses can be saved to history.
/// - Supports markdown rendering for AI messages.
///
/// Requires:
/// - [ChemnorApi] for backend communication.
/// - [Hive] for local history storage.
/// - [gpt_markdown] for markdown rendering.
///
/// UI:
/// - Displays compound name in the AppBar if available.
/// - Shows loading indicator while awaiting AI response.
/// - Provides input field and action buttons for user interaction.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:hive/hive.dart';
import '../services/ChemnorApi.dart';
import '../screens/settings_controller.dart';

class ChatWidget extends StatefulWidget {
  final Map<String, dynamic>? compoundData;

  const ChatWidget({Key? key, this.compoundData}) : super(key: key);

  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final List<({Image? image, String? text, bool fromUser})> _generatedContent = <({Image? image, String? text, bool fromUser})>[];
  bool _loading = false;
  final ChemnorApi ApiSrv = ChemnorApi();

  @override
  void initState() {
    super.initState();

    // If compoundData is provided, send an initial message to ChemNOR about the compound
    if (widget.compoundData != null) {
      final compoundInfo = widget.compoundData!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      final initialPrompt =
          "Let's discuss the following chemical compound:\n$compoundInfo\n"
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
      String contextText = '';
      if (widget.compoundData != null) {
        contextText = widget.compoundData!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        contextText = "Compound context:\n$contextText\n\n$message";
      } else {
        contextText = message;
      }

      _generatedContent.add((image: null, text: message, fromUser: false));
      final response = await ApiSrv.fetchResponse(contextText);
      final text = processAIText(response);
      if (text.isNotEmpty) {
        _generatedContent.add((image: null, text: text, fromUser: false));
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.compoundData?['name'] != null ? 'Chat: ${widget.compoundData!['name']}' : 'Chat')),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemBuilder: (context, idx) {
                    final content = _generatedContent[idx];
                    return MessageWidget(text: content.text, image: content.image, isFromUser: content.fromUser);
                  },
                  itemCount: _generatedContent.length,
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
                                // Chemistry-related action: call chemist method from ChemnorApi
                                if (widget.compoundData != null && widget.compoundData!['cid'] != null) {
                                  final cid = widget.compoundData!['cid'].toString();
                                  final result = await ApiSrv.chemist(cid);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chemist result: $result')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No compound selected.')));
                                }
                              }
                              : null,
                      icon: Icon(
                        Icons.science, // Chemistry-related icon
                        color: _loading ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
                      ),
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
      // Build context: compound info + chat history + current question
      String prompt = '';
      if (widget.compoundData != null) {
        final compoundContext = widget.compoundData!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        prompt += "Compound context:\n$compoundContext\n\n";
      }
      // Add previous chat history
      if (_generatedContent.isNotEmpty) {
        prompt += "Chat history:\n";
        for (final msg in _generatedContent) {
          if (msg.text != null) {
            prompt += msg.fromUser ? "User: ${msg.text}\n" : "AI: ${msg.text}\n";
          }
        }
        prompt += "\n";
      }
      // Add the new user question
      prompt += "Answer the following question about the compound above:\n$message";

      final response = await ApiSrv.fetchResponse(prompt);
      setState(() {
        _generatedContent.add((image: null, text: processAIText(response), fromUser: false));
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
    final isAI = !isFromUser;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (image != null) image!,
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isFromUser ? const Color.fromARGB(255, 40, 0, 114) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (text != null) GptMarkdown(text!),
                if (isAI && text != null)
                  IconButton(
                    icon: const Icon(Icons.bookmark_add, color: Colors.amber, size: 22),
                    tooltip: 'Save to history',
                    onPressed: () async {
                      final box = Hive.box<String>('historyBox');
                      await box.add(text!);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to history!')));
                    },
                  ),
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
