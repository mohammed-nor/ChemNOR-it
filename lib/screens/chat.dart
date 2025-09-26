/// A chat widget for interacting with a chemistry assistant AI about a specific chemical compound.
///
/// This file implements two main chat interfaces:
/// 1. ChatWidget - For compound-specific chat with context about a chemical compound
/// 2. ChatPage - For general chemistry chat without specific compound context
///
/// Both interfaces share similar UI and functionality but differ in their initialization
/// and context management.

// Import necessary packages
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:flutter/services.dart'; // For clipboard functionality
import 'package:gpt_markdown/gpt_markdown.dart'; // For markdown rendering
import 'package:hive/hive.dart'; // Local storage
import '../services/ChemnorApi.dart'; // API service for AI interaction
import '../screens/settings_controller.dart'; // App settings

/// Compound-specific chat widget that can be initialized with compound data
class ChatWidget extends StatefulWidget {
  // Optional compound data to provide context for the chat
  final Map<String, dynamic>? compoundData;

  // Constructor with optional compound data
  const ChatWidget({Key? key, this.compoundData}) : super(key: key);

  @override
  // Create state for this widget
  _ChatWidgetState createState() => _ChatWidgetState();
}

/// State class for the compound-specific chat widget
class _ChatWidgetState extends State<ChatWidget> {
  // Scroll controller for the chat messages list
  final ScrollController _scrollController = ScrollController();

  // Text controller for the input field
  final TextEditingController _textController = TextEditingController();

  // Focus node for the text input field
  final FocusNode _textFieldFocus = FocusNode();

  // List to store chat messages (using records for type safety)
  final List<({Image? image, String? text, bool fromUser})> _generatedContent = <({Image? image, String? text, bool fromUser})>[];

  // Flag to track if a request is in progress
  bool _loading = false;

  // API service for communication with backend
  ChemnorApi ApiSrv = ChemnorApi();

  @override
  // Initialize state when widget is created
  void initState() {
    super.initState();

    // If compound data is provided, send an initial message about it
    if (widget.compoundData != null) {
      // Format compound data as a string
      final compoundInfo = widget.compoundData!.entries.map((e) => '${e.key}: ${e.value}').join('\n');

      // Create initial prompt with compound context
      final initialPrompt =
          "Let's discuss the following chemical compound:\n$compoundInfo\n"
          "As an expert chemistry assistant. Answering questions and provide insights about this compound based on its data above.";

      // Send initial message to AI
      _sendInitialCompoundMessage(initialPrompt);
    }
  }

  /// Process AI response text to improve conversational flow
  /// This function replaces "you are" with "i am" to make responses sound more natural
  String processAIText(String? text) {
    if (text == null) return '';
    // Only replace "you are" (case-insensitive) with "i am"
    return text.replaceAllMapped(RegExp(r'you are', caseSensitive: false), (match) => 'i am');
  }

  /// Send initial message with compound information to the AI
  Future<void> _sendInitialCompoundMessage(String message) async {
    setState(() {
      _loading = true; // Show loading indicator
    });

    try {
      String contextText = '';
      // Add compound context if available
      if (widget.compoundData != null) {
        // Format compound data
        contextText = widget.compoundData!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        // Create full prompt with context
        contextText = "Compound context:\n$contextText\n\n$message";
      } else {
        contextText = message; // Just use message if no compound data
      }

      // Add message to UI as system message
      _generatedContent.add((image: null, text: message, fromUser: false));

      // Fetch response from API
      final response = await ApiSrv.fetchResponse(contextText);

      // Process response text
      final text = processAIText(response);

      // Add response to chat if not empty
      if (text.isNotEmpty) {
        _generatedContent.add((image: null, text: text, fromUser: false));
      }

      // Update UI state
      setState(() {
        _loading = false; // Hide loading indicator
      });
    } catch (e) {
      // Handle errors
      if (mounted) {
        ApiSrv.showError(context, e.toString());
        setState(() {
          _loading = false; // Hide loading indicator
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

  /// Send a new chat message from the user and get AI response
  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) return; // Don't send empty messages

    setState(() {
      _loading = true; // Show loading indicator
      // Add user message to chat
      _generatedContent.add((image: null, text: message, fromUser: true));
    });

    try {
      // Build prompt with context, history and current question
      String prompt = '';

      // Add compound context if available
      if (widget.compoundData != null) {
        // Format compound data
        String compoundContext = widget.compoundData!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        prompt = "Compound context:\n$compoundContext\n\n";
      }

      // Add previous chat history for context
      if (_generatedContent.isNotEmpty) {
        prompt += "Previous conversation:\n";
        for (final msg in _generatedContent.sublist(0, _generatedContent.length - 1)) {
          if (msg.text != null) {
            prompt += msg.fromUser ? "User: ${msg.text}\n" : "Assistant: ${msg.text}\n";
          }
        }
      }

      // Add current question
      prompt += "Answer the following question about the compound above:\n$message";

      // Get response from API
      final response = await ApiSrv.fetchResponse(prompt);

      // Process and add response to chat
      final processedResponse = processAIText(response);
      _generatedContent.add((image: null, text: processedResponse, fromUser: false));

      // Update UI state
      setState(() {
        _loading = false; // Hide loading indicator
      });

      // Scroll to bottom after a short delay
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      // Handle errors
      ApiSrv.showError(context, e.toString());
      setState(() {
        _loading = false; // Hide loading indicator
      });
    } finally {
      // Clear input field and set focus for next message
      _textController.clear();
      _textFieldFocus.requestFocus();
    }
  }
}

/// Widget to display individual chat messages
class MessageWidget extends StatelessWidget {
  // Message content
  final Image? image; // Optional image attachment
  final String? text; // Message text
  final bool isFromUser; // Whether message is from user or AI

  // Constructor
  const MessageWidget({super.key, this.image, this.text, required this.isFromUser});

  @override
  Widget build(BuildContext context) {
    final isAI = !isFromUser; // Helper flag for clarity

    // Create row layout with appropriate alignment
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      // Align user messages to right, AI messages to left
      mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        // Show image if available
        if (image != null) image!,

        // Message bubble
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // User messages have background color, AI messages are transparent
              color: isFromUser ? const Color.fromARGB(255, 40, 0, 114) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Render message text as markdown if available
                if (text != null) GptMarkdown(text!),

                // Add save button for AI messages
                if (isAI && text != null)
                  IconButton(
                    icon: const Icon(Icons.bookmark_add, color: Colors.amber, size: 22),
                    tooltip: 'Save to history',
                    // Save message to history box on press
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

/// General chat widget for conversations without compound context
class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

/// State class for the general chat page
class _ChatPageState extends State<ChatPage> {
  // Scroll controller for the chat messages list
  final ScrollController _scrollController = ScrollController();

  // Text controller for the input field
  final TextEditingController _textController = TextEditingController();

  // Focus node for the text input field
  final FocusNode _textFieldFocus = FocusNode();

  // List to store chat messages
  final List<({Image? image, String? text, bool fromUser})> _chatMessages = <({Image? image, String? text, bool fromUser})>[];

  // Flag to track if a request is in progress
  bool _loading = false;

  // API service for communication with backend
  final ChemnorApi apiService = ChemnorApi();

  @override
  // Initialize state when widget is created
  void initState() {
    super.initState();
    // Send welcome message when chat is opened
    _sendWelcomeMessage();
  }

  @override
  // Update when dependencies change (e.g., settings)
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the latest API key from Hive
    final currentKey = (Hive.box('settingBox').get('geminiapikey') as String?) ?? '';
    // Update API service if key has changed
    if (apiService.apikey != currentKey) {
      apiService.apikey = currentKey;
    }
  }

  /// Send initial welcome message from the AI
  Future<void> _sendWelcomeMessage() async {
    setState(() {
      _loading = true; // Show loading indicator
    });

    try {
      // Prompt for welcome message
      const welcomePrompt =
          "You are ChemNOR, a helpful chemistry assistant. Provide a brief welcome message (2-3 sentences) to a user who has just opened the chat. Explain that you can answer chemistry questions and that they can use the 'Chemist' button for specific chemical compound analysis by CID.";

      // Fetch welcome message from API
      final response = await apiService.fetchResponse(welcomePrompt);

      // Add response to chat
      setState(() {
        _chatMessages.add((image: null, text: response, fromUser: false));
        _loading = false; // Hide loading indicator
      });
    } catch (e) {
      // Handle errors
      if (mounted) {
        apiService.showError(context, e.toString());
        setState(() {
          _loading = false; // Hide loading indicator
        });
      }
    }
  }

  /// Send a new message and receive AI response
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
      String prompt = ".\n\n";

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
              //keyboardType: TextInputType.number,
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
                    //return MessageWidget(text: message.text, image: message.image, isFromUser: message.fromUser);
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
        decoration: BoxDecoration(color: isFromUser ? const Color.fromARGB(255, 40, 0, 114) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (text != null) GptMarkdown(text!),
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
