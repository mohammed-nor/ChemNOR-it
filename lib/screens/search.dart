import 'package:chem_nor/chem_nor.dart';
import 'package:flutter/material.dart';

import '../keys.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({
    super.key,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final ApiSrv = ChemNOR(genAiApiKey: gmnkey);

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _compoundsResult = [];
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _searchCompounds(String description) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await ApiSrv.findListOfCompounds(description);
      setState(() {
        _isLoading = false;
        _compoundsResult = results as List<Map<String, dynamic>>;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: 'ChemNOR ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    TextSpan(
                      text: 'it!',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.redAccent,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'C',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'hemical ',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'H',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'euristic ',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'E',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'valuation of ',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'M',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'olecules ',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'N',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'etworking for ',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'O',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'ptimized ',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'R',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    TextSpan(
                      text: 'eactivity',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search molecules by description or smiles',
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () async => await _searchCompounds(_searchController.text),
              ),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) async => await _searchCompounds(value),
          ),
        ),
        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_errorMessage.isNotEmpty)
          Center(child: Text(_errorMessage))
        else if (_compoundsResult.isNotEmpty)
          const Expanded(
            child: Text("heello"),
          )
        else
          Center(
            child: Text('Enter a description or SMILES string and press search.'),
          ),
      ],
    );
  }
}
