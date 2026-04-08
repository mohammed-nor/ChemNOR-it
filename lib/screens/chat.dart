/// A chat widget for interacting with a chemistry assistant AI about a specific chemical compound.
///
/// This file implements two main chat interfaces:
/// 1. ChatWidget - For compound-specific chat with context about a chemical compound
/// 2. ChatPage - For general chemistry chat without specific compound context
///
/// Both interfaces share similar UI and functionality but differ in their initialization
/// and context management.
library;

// Import necessary packages
import 'package:flutter/material.dart';
import 'package:chemnor_it/main.dart'; // Flutter UI components
// For clipboard functionality
import 'package:gpt_markdown/gpt_markdown.dart'; // For markdown rendering
import 'package:hive/hive.dart'; // Local storage
import '../services/ChemnorApi.dart'; // API service for AI interaction
// App settings

/// Compound-specific chat widget that can be initialized with compound data
class ChatWidget extends StatefulWidget {
  // Optional compound data to provide context for the chat
  final Map<String, dynamic>? compoundData;

  // Constructor with optional compound data
  const ChatWidget({super.key, this.compoundData});

  @override
  // Create state for this widget
  _ChatWidgetState createState() => _ChatWidgetState();
}

/// State class for the compound-specific chat widget
class _ChatWidgetState extends State<ChatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  // Scroll controller for the chat messages list
  final ScrollController _scrollController = ScrollController();

  // Text controller for the input field
  final TextEditingController _textController = TextEditingController();

  // Focus node for the text input field
  final FocusNode _textFieldFocus = FocusNode();

  // List to store chat messages (using records for type safety)
  final List<({Image? image, String? text, bool fromUser})> _generatedContent =
      <({Image? image, String? text, bool fromUser})>[];

  // Flag to track if a request is in progress
  bool _loading = false;

  // API service for communication with backend
  ChemnorApi ApiSrv = ChemnorApi();

  @override
  // Initialize state when widget is created
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

    // If compound data is provided, send an initial message about it
    if (widget.compoundData != null) {
      // Format compound data as a string
      final compoundInfo = widget.compoundData!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');

      // Create initial prompt with compound context
      final initialPrompt =
          "Let's discuss the following chemical compound:\n$compoundInfo\n"
          "As an expert chemistry assistant. Answering questions and provide insights about this compound based on its data above.";

      // Send initial message to AI
      _sendInitialCompoundMessage(initialPrompt);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  /// Process AI response text to improve conversational flow
  /// This function replaces "you are" with "i am" to make responses sound more natural
  String processAIText(String? text) {
    if (text == null) return '';
    // Only replace "you are" (case-insensitive) with "i am"
    return text.replaceAllMapped(
      RegExp(r'you are', caseSensitive: false),
      (match) => 'i am',
    );
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
        contextText = widget.compoundData!.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
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
    final baseFontSize = settingsController.value.fontSize;
    final textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt...',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
    );
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            widget.compoundData?['name'] != null
                ? 'Chat: ${widget.compoundData!['name']}'
                : 'Chat',
            style: TextStyle(
              fontSize: baseFontSize + 4.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
                    Positioned(
                      top: 100,
                      right: -100,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6366F1).withOpacity(0.06),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Chat Content
            Padding(
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
                        return MessageWidget(
                          text: content.text,
                          image: content.image,
                          isFromUser: content.fromUser,
                        );
                      },
                      itemCount: _generatedContent.length,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 25,
                      horizontal: 15,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            focusNode: _textFieldFocus,
                            decoration: textFieldDecoration,
                            controller: _textController,
                            onSubmitted: _sendChatMessage,
                          ),
                        ),
                        const SizedBox.square(dimension: 15),
                        IconButton(
                          onPressed: !_loading
                              ? () async {
                                  // Chemistry-related action: call chemist method from ChemnorApi
                                  if (widget.compoundData != null &&
                                      widget.compoundData!['cid'] != null) {
                                    final cid = widget.compoundData!['cid']
                                        .toString();
                                    final result = await ApiSrv.chemist(cid);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Chemist result: $result',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No compound selected.'),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: Icon(
                            Icons.science, // Chemistry-related icon
                            color: _loading
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (!_loading)
                          IconButton(
                            onPressed: () async {
                              _sendChatMessage(_textController.text);
                            },
                            icon: Icon(
                              Icons.send,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        else
                          const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        String compoundContext = widget.compoundData!.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
        prompt = "Compound context:\n$compoundContext\n\n";
      }

      // Add previous chat history for context
      if (_generatedContent.isNotEmpty) {
        prompt += "Previous conversation:\n";
        for (final msg in _generatedContent.sublist(
          0,
          _generatedContent.length - 1,
        )) {
          if (msg.text != null) {
            prompt += msg.fromUser
                ? "User: ${msg.text}\n"
                : "Assistant: ${msg.text}\n";
          }
        }
      }

      // Add current question
      prompt +=
          "Answer the following question about the compound above:\n$message";

      // Get response from API
      final response = await ApiSrv.fetchResponse(prompt);

      // Process and add response to chat
      final processedResponse = processAIText(response);
      _generatedContent.add((
        image: null,
        text: processedResponse,
        fromUser: false,
      ));

      // Update UI state
      setState(() {
        _loading = false; // Hide loading indicator
      });

      // Scroll to bottom after a short delay
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
  const MessageWidget({
    super.key,
    this.image,
    this.text,
    required this.isFromUser,
  });

  @override
  Widget build(BuildContext context) {
    final baseFontSize = settingsController.value.fontSize;
    final isAI = !isFromUser;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isFromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (isAI)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.science_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: isFromUser
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isAI ? theme.colorScheme.surface : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isFromUser ? 20 : 4),
                  bottomRight: Radius.circular(isFromUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isAI
                    ? Border.all(color: Colors.white.withOpacity(0.05))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (text != null)
                    GptMarkdown(
                      text!,
                      style: TextStyle(
                        color: isFromUser
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                        fontSize: baseFontSize + 1.0,
                        height: 1.4,
                      ),
                    ),
                  if (isAI && text != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final box = Hive.box<String>('historyBox');
                              await box.add(text!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Saved to history!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.bookmark_add_outlined,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isFromUser)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                child: Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// General chat widget for conversations without compound context
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

/// State class for the general chat page
class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  // Scroll controller for the chat messages list
  final ScrollController _scrollController = ScrollController();

  // Text controller for the input field
  final TextEditingController _textController = TextEditingController();

  // Focus node for the text input field
  final FocusNode _textFieldFocus = FocusNode();

  // List to store chat messages
  final List<({Image? image, String? text, bool fromUser})> _chatMessages =
      <({Image? image, String? text, bool fromUser})>[];

  // Flag to track if a request is in progress
  bool _loading = false;

  // API service for communication with backend
  final ChemnorApi apiService = ChemnorApi();

  @override
  // Initialize state when widget is created
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

    // Send welcome message when chat is opened
    _sendWelcomeMessage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  @override
  // Update when dependencies change (e.g., settings)
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the latest API key from Hive
    final currentKey =
        (Hive.box('settingBox').get('geminiapikey') as String?) ?? '';
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
            prompt += msg.fromUser
                ? "User: ${msg.text}\n"
                : "AI: ${msg.text}\n";
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
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
      builder: (context) => AlertDialog(
        title: Text('Chemical Application'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter the chemical application you desired',
          ),
          controller: cidController,
          //keyboardType: TextInputType.number,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(cidController.text),
            child: Text('Submit'),
          ),
        ],
      ),
    );

    if (cid != null && cid.isNotEmpty) {
      setState(() {
        _loading = true;
        _chatMessages.add((
          image: null,
          text: "Brainstorming on: $cid...",
          fromUser: false,
        ));
      });

      try {
        final result = await apiService.chemist(cid);

        setState(() {
          _chatMessages.add((
            image: null,
            text: "Chemical analysis result:\n$result",
            fromUser: false,
          ));
          _loading = false;
        });

        // Scroll to bottom
        await Future.delayed(const Duration(milliseconds: 100));
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
    final baseFontSize = settingsController.value.fontSize;
    final textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Type a message...',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                    Positioned(
                      bottom: 100,
                      left: -100,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4F46E5).withOpacity(0.06),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
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
                              text: 'Chat\n',
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

                      const SizedBox(height: 20),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemBuilder: (context, idx) {
                        final message = _chatMessages[idx];
                        return MessageBubble(
                          text: message.text,
                          image: message.image,
                          isFromUser: message.fromUser,
                        );
                      },
                      itemCount: _chatMessages.length,
                    ),
                  ),
                  if (_loading)
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: !_loading ? _useChemistFunction : null,
                        icon: Icon(Icons.science_rounded),
                        tooltip: 'Chemist Function',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          focusNode: _textFieldFocus,
                          controller: _textController,
                          decoration: textFieldDecoration,
                          onSubmitted: (value) => _sendMessage(value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: !_loading
                            ? () => _sendMessage(_textController.text)
                            : null,
                        icon: Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    this.image,
    this.text,
    required this.isFromUser,
  });

  final Image? image;
  final String? text;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    final baseFontSize = settingsController.value.fontSize;
    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isFromUser
              ? const Color.fromARGB(255, 40, 0, 114)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (text != null) GptMarkdown(text!),
            if (!isFromUser && text != null)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.bookmark_add, color: Colors.amber, size: 22),
                  onPressed: () async {
                    final box = Hive.box<String>('historyBox');
                    await box.add(text!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to history!')),
                    );
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
