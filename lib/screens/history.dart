import 'package:chemnor__it/main.dart';
import 'package:flutter/material.dart';
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
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(title: GptMarkdown(value ?? ''), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => box.delete(key))),
              );
            },
          );
        },
      ),
    );
  }
}
