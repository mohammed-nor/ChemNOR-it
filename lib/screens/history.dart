/// A widget that displays a list of saved history messages from a Hive box.
///
/// The [HistoryWidget] shows each saved message in a card, allowing users to:
/// - View the message rendered as markdown.
/// - Copy the message to the clipboard by long-pressing on it.
/// - Delete individual messages using the delete icon.
///
/// If there are no saved messages, a placeholder text is shown.
///
/// The widget listens to changes in the Hive box and updates the UI accordingly.
library;

// Import necessary packages
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:flutter/services.dart'; // For clipboard access
import 'package:gpt_markdown/gpt_markdown.dart'; // For markdown rendering
import 'package:hive_flutter/adapters.dart'; // For Hive UI integration
import 'package:chemnor_it/main.dart'; // Access global settings

/// Main widget for displaying saved chat history
class HistoryWidget extends StatefulWidget {
  // Constructor with key parameter for widget identification
  const HistoryWidget({super.key});

  @override
  // Create state for this widget
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

/// State class for the history widget
class _HistoryWidgetState extends State<HistoryWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  // Hive box to store string messages
  late Box<String> _historyBox;

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

    // Get reference to the historyBox
    _historyBox = Hive.box<String>('historyBox');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseFontSize = settingsController.value.fontSize;
    final theme = Theme.of(context);
    final fontSize = settingsController.value.fontSize;

    return Scaffold(
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
                    top: -100,
                    right: -50,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: -100,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4F46E5).withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 80.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: RichText(
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
                          text: 'History\n',
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
              ValueListenableBuilder(
                valueListenable: _historyBox.listenable(),
                builder: (context, Box<String> box, _) {
                  if (box.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: Colors.white.withOpacity(0.1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No saved messages yet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: baseFontSize + 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, idx) {
                        final key = box.keyAt(idx);
                        final value = box.get(key);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onLongPress: value != null
                                  ? () {
                                      Clipboard.setData(
                                        ClipboardData(text: value),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Copied to clipboard!'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.bookmark_rounded,
                                                size: 14,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Saved Item',
                                                style: TextStyle(
                                                  fontSize: baseFontSize - 3.0,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          onPressed: () => box.delete(key),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    GptMarkdown(
                                      value ?? '',
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Long press to copy content',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.2),
                                        fontSize: baseFontSize - 7.0,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }, childCount: box.length),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
