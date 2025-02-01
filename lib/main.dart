// main.dart
import 'package:flutter/material.dart';
import 'api_service.dart';

void main() {
  runApp(const MoleculeSearchApp());
}

class MoleculeSearchApp extends StatelessWidget {
  const MoleculeSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Molecule Search',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MoleculeSearchScreen(),
    );
  }
}

class MoleculeSearchScreen extends StatefulWidget {
  const MoleculeSearchScreen({super.key});

  @override
  _MoleculeSearchScreenState createState() => _MoleculeSearchScreenState();
}

class _MoleculeSearchScreenState extends State<MoleculeSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ChemPubService _chemPubService = ChemPubService('YOUR_CHEMPUB_API_KEY');
  final AIService _aiService = AIService('YOUR_AI_API_KEY');
  List<MoleculeResult> _results = [];
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _searchMolecules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Step 1: AI-powered query interpretation
      final interpretedQuery = await _aiService.interpretQuery(
        _queryController.text,
      );

      // Step 2: Search ChemPub with interpreted parameters
      final results = await _chemPubService.searchCompounds(
        properties: interpretedQuery.properties,
        query: interpretedQuery.searchTerms,
        maxResults: 10,
      );

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Molecule Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: 'Describe your desired molecules',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchMolecules,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final molecule = _results[index];
                    return ListTile(
                      title: Text(molecule.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SMILES: ${molecule.smiles}'),
                          Text('Molecular Weight: ${molecule.molecularWeight}'),
                          if (molecule.bioactivity != null)
                            Text('Bioactivity: ${molecule.bioactivity}'),
                        ],
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
