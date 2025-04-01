import 'package:chemnor_it/services/api.dart';
import 'package:chem_nor/chem_nor.dart';
import 'package:flutter/material.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({
    required this.apiKey,
    super.key,
  });

  final String apiKey;

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final ApiSrv = ChemNOR(genAiApiKey: gmnapikey);

  @override
  initState() {
    super.initState();
  }

  final TextEditingController _searchController = TextEditingController();

  final List<int> _cidcompounds = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String title = '';

  Future<String> _searchCompounds(String description) async {
    String _compounds = '';
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      //title = tmp;
    });

    try {
      final results = await ApiSrv.findListOfCompounds(description ?? '');
      setState(() {
        _compounds = results.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching compounds: ${e.toString()}';
        _isLoading = false;
      });
    }
    return _compounds;
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
        _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : Expanded(
                    child: FutureBuilder(
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.none) {
                          return Center(child: Text("No Connection"));
                        } else if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}"));
                        } else if (!snapshot.hasData) {
                          return Center(child: Text("No data available"));
                        } else {
                          return Center(child: Text(snapshot.data.toString()));
                        }
                      },
                      future: _searchCompounds,
                    ),
                  ),
      ],
    );
  }
}
