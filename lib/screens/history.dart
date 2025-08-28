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
import 'package:chemnor__it/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:hive_flutter/adapters.dart';
import '../screens/settings_controller.dart';

class HistoryWidget extends StatefulWidget {
  const HistoryWidget({super.key});

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  late Box<String> _historyBox;

  @override
  void initState() {
    super.initState();
    _historyBox = Hive.box<String>('historyBox');
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = settingsController.value.fontSize;
    final apiKey = settingsController.value.geminiApiKey;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved History')),
      body: ValueListenableBuilder(
        valueListenable: _historyBox.listenable(),
        builder: (context, Box<String> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No saved messages.'));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, idx) {
              final key = box.keyAt(idx);
              final value = box.get(key);
              return Card(
                color: Colors.deepPurple.withOpacity(0.1),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, right: 40.0, left: 8.0, bottom: 8.0),
                      child: ListTile(
                        title: GptMarkdown(value ?? ''),
                        onLongPress:
                            value != null
                                ? () {
                                  Clipboard.setData(ClipboardData(text: value));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                                }
                                : null,
                      ),
                    ),
                    Positioned(top: 0, right: 0, child: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => box.delete(key), tooltip: 'Delete')),
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
