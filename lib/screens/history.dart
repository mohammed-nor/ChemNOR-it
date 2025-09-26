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

// Import necessary packages
import 'package:chemnor__it/main.dart'; // For app-wide configurations
import 'package:flutter/material.dart'; // Flutter UI components
import 'package:flutter/services.dart'; // For clipboard access
import 'package:hive/hive.dart'; // For local storage
import 'package:gpt_markdown/gpt_markdown.dart'; // For markdown rendering
import 'package:hive_flutter/adapters.dart'; // For Hive UI integration
import '../screens/settings_controller.dart'; // For app settings

/// Main widget for displaying saved chat history
class HistoryWidget extends StatefulWidget {
  // Constructor with key parameter for widget identification
  const HistoryWidget({super.key});

  @override
  // Create state for this widget
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

/// State class for the history widget
class _HistoryWidgetState extends State<HistoryWidget> {
  // Hive box to store string messages
  late Box<String> _historyBox;

  @override
  // Initialize state when widget is created
  void initState() {
    super.initState();
    // Get reference to the historyBox
    _historyBox = Hive.box<String>('historyBox');
  }

  @override
  // Build the UI for the history widget
  Widget build(BuildContext context) {
    // Get user preferences from settings controller
    final fontSize = settingsController.value.fontSize;
    final apiKey = settingsController.value.geminiApiKey;
    // Note: These values are retrieved but not currently used in the UI

    return Scaffold(
      // App bar with title
      appBar: AppBar(title: const Text('Saved History')),

      // Main content - a reactive list that updates when Hive data changes
      body: ValueListenableBuilder(
        // Listen for changes to the history box
        valueListenable: _historyBox.listenable(),
        builder: (context, Box<String> box, _) {
          // If no history items, show placeholder
          if (box.isEmpty) {
            return const Center(child: Text('No saved messages.'));
          }

          // Build scrollable list of history items
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, idx) {
              // Get the key and value from the box at this index
              final key = box.keyAt(idx);
              final value = box.get(key);

              // Create a card for each history item
              return Card(
                color: Colors.deepPurple.withOpacity(0.1),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Stack(
                  children: [
                    // Main content with padding for delete button
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, right: 40.0, left: 8.0, bottom: 8.0),
                      child: ListTile(
                        // Display message content as markdown
                        title: GptMarkdown(value ?? ''),
                        // Copy to clipboard on long press
                        onLongPress:
                            value != null
                                ? () {
                                  Clipboard.setData(ClipboardData(text: value));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                                }
                                : null,
                      ),
                    ),

                    // Delete button positioned in top-right corner
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => box.delete(key), // Delete this entry
                        tooltip: 'Delete',
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
