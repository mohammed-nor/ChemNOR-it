import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:hive/hive.dart';
import '../services/ChemnorApi.dart';

class GeneralChatPage extends StatefulWidget {
  const GeneralChatPage({Key? key}) : super(key: key);

  @override
  _GeneralChatPageState createState() => _GeneralChatPageState();
}

class _GeneralChatPageState extends State<GeneralChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final List<({Image? image, String? text, bool fromUser})> _chatMessages = <({Image? image, String? text, bool fromUser})>[];
  bool _loading = false;
  final ChemnorApi apiService = ChemnorApi();

  @override
  void initState() {
    super.initState();
    // Send welcome message when chat is initialized
    _sendWelcomeMessage();
  }

  Future<void> _sendWelcomeMessage() async {
    setState(() {
      _loading = true;
    });

    try {
      const welcomePrompt =
          "You are ChemNOR, a helpful chemistry assistant. Provide a brief welcome message (2-3 sentences) to a user who has just opened the chat. Explain that you can answer chemistry questions and that they can use the 'Chemist' button for specific chemical compound analysis by CID.";
      final response = await apiService.fetchResponse(welcomePrompt);

      setState(() {
        _chatMessages.add((image: null, text: response, fromUser: false));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        apiService.showError(context, e.toString());
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _chatMessages.add((image: null, text: message, fromUser: true));
    });

    _textController.clear();
    _textFieldFocus.requestFocus();

    try {
      // Build context from previous chat history (excluding the last message which is the current query)
      String prompt = "You are ChemNOR, a helpful chemistry assistant. Respond to the user's latest message.\n\n";

      // Add previous messages as context
      if (_chatMessages.length > 1) {
        prompt += "Previous conversation:\n";
        // Only include messages before the current one
        for (int i = 0; i < _chatMessages.length - 1; i++) {
          final msg = _chatMessages[i];
          if (msg.text != null) {
            prompt += msg.fromUser ? "User: ${msg.text}\n" : "AI: ${msg.text}\n";
          }
        }
        prompt += "\n";
      }

      // Add the current query explicitly
      prompt += "User's current message: $message\n\n";
      prompt += "Please provide a helpful response to the user's message.";

      final response = await apiService.fetchResponse(prompt);

      setState(() {
        _chatMessages.add((image: null, text: response, fromUser: false));
        _loading = false;
      });

      // Scroll to bottom after a short delay
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      apiService.showError(context, e.toString());
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _useChemistFunction() async {
    // Show dialog to get CID input
    final TextEditingController cidController = TextEditingController();
    final String? cid = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chemical Application'),
            content: TextField(
              decoration: const InputDecoration(hintText: 'Enter the chemical application you desired'),
              controller: cidController,
              keyboardType: TextInputType.number,
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(cidController.text), child: const Text('Submit')),
            ],
          ),
    );

    if (cid != null && cid.isNotEmpty) {
      setState(() {
        _loading = true;
        _chatMessages.add((image: null, text: "Brainstorming on: $cid...", fromUser: false));
      });

      try {
        final result = await apiService.chemist(cid);

        setState(() {
          _chatMessages.add((image: null, text: "Chemical analysis result:\n$result", fromUser: false));
          _loading = false;
        });

        // Scroll to bottom
        await Future.delayed(const Duration(milliseconds: 100));
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      } catch (e) {
        apiService.showError(context, e.toString());
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
      hintText: 'Type a message...',
      border: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)),
      focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)),
    );

    return SafeArea(
      child: Scaffold(
        body: Padding(
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

              /*
        appBar: AppBar(
          title: const Text('ChemNOR Chat'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('About ChemNOR Chat'),
                        content: const Text(
                          'This is a general chat interface where you can ask questions about chemistry.\n\n'
                          'Use the "Chemist" button to analyze specific chemical compounds by CID.',
                        ),
                        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
                      ),
                );
              },
            ),
          ],
        ),*/
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemBuilder: (context, idx) {
                    final message = _chatMessages[idx];
                    return MessageBubble(text: message.text, image: message.image, isFromUser: message.fromUser);
                  },
                  itemCount: _chatMessages.length,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(child: TextField(autofocus: true, focusNode: _textFieldFocus, decoration: textFieldDecoration, controller: _textController, onSubmitted: _sendMessage, maxLines: null)),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _loading ? null : () => _useChemistFunction(),
                      icon: Icon(Icons.science, color: _loading ? Theme.of(context).colorScheme.secondary.withOpacity(0.5) : Theme.of(context).colorScheme.secondary),
                      tooltip: 'Use Chemist Function',
                    ),
                    IconButton(
                      onPressed: _loading ? null : () => _sendMessage(_textController.text),
                      icon: Icon(Icons.send, color: _loading ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(backgroundColor: Theme.of(context).colorScheme.surface, valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({Key? key, this.image, this.text, required this.isFromUser}) : super(key: key);

  final Image? image;
  final String? text;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: isFromUser ? const Color.fromARGB(255, 40, 0, 114) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (text != null) isFromUser ? Text(text!, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)) : GptMarkdown(text!),
            if (image != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: image!),
            if (!isFromUser && text != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.bookmark_add, color: Colors.amber, size: 22),
                  onPressed: () async {
                    final box = Hive.box<String>('historyBox');
                    await box.add(text!);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to history!')));
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
