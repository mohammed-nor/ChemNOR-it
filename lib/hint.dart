User: Give a flutter code that take an input trom text field and use it to fetch json format data then parse it and return cards in a listview widget
Kimi: Here's a Flutter code example that demonstrates fetching and displaying JSON data based on user input:

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSON Fetch Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: JsonFetchScreen(),
    );
  }
}

class JsonFetchScreen extends StatefulWidget {
  @override
  _JsonFetchScreenState createState() => _JsonFetchScreenState();
}

class _JsonFetchScreenState extends State<JsonFetchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _data = [];
  bool _isLoading = false;

  Future<void> _fetchData(String query) async {
    setState(() => _isLoading = true);
    _data = [];

    try {
      // Replace with your actual API endpoint
      final response = await http.get(Uri.parse(
          'https://jsonplaceholder.typicode.com/posts?title=$query'));

      if (response.statusCode == 200) {
        setState(() {
          _data = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JSON Fetch Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter search query',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchData(_controller.text),
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _data.length,
                      itemBuilder: (context, index) {
                        final item = _data[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Title: ${item['title']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Body: ${item['body']}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

This code includes:

1. A text field for user input
2. A search button to trigger the API call
3. Loading indicator while fetching data
4. ListView with Card widgets displaying parsed JSON data
5. Error handling using SnackBar

Key features:
- Uses the http package for network requests
- Parses JSON data using dart:convert
- Displays results in a scrollable ListView
- Shows loading state during API calls
- Handles errors gracefully
- Uses Cards for displaying individual items

To use this code:

1. Add the http dependency to your `pubspec.yaml`:
```yaml
dependencies:
  http: ^0.13.5
```

2. Replace the API endpoint with your actual JSON endpoint
3. Adjust the JSON parsing and Card content based on your data structure

The example uses JSONPlaceholder's mock API. You'll need to modify the:
- API endpoint URL
- JSON parsing logic
- Card content display
- Error handling messages

You can customize the Card appearance by modifying the Card widget's properties and adding more fields from your JSON data.
