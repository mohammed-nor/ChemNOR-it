import 'package:ChemNOR_it/api.dart';
import 'package:chem_nor/chem_nor.dart';
import 'package:flutter/cupertino.dart';
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
  late Future<List<Compound>> futureCompounds;
  @override
  void initState() {
    super.initState();
    futureCompounds = fetchCompounds(cids);
  }

  final TextEditingController _searchController = TextEditingController();
  String _compounds = '';
  List<int> _cidcompounds = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String title = '';

  Future<void> _searchCompounds(String description) async {
    //dynamic tmp = await fetchPropertyForCompounds(2244, 'Name');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      //title = tmp;
    });

    try {
      final results = await ApiSrv.getCompoundProperties(int.tryParse(description) == null ? 2244 : int.tryParse(description)!);
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Compound>>(
        future: futureCompounds,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.none) {
            return Center(child: Text("No Connection"));
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No data available"));
          } else {
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
                        onPressed: () => _searchCompounds(_searchController.text),
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _searchCompounds(value),
                  ),
                ),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(child: Text(_errorMessage))
                        : Expanded(
                            child: ListView.builder(
                              itemCount: _cidcompounds.length,
                              itemBuilder: (context, index) {
                                print(_cidcompounds[index]);
                                //return Text(_cidcompounds[index].toString());
                                return Card(
                                  child: ListTile(
                                    title: Text(title),
                                    subtitle: Text(
                                      '$_compounds\n'
                                      'CID: ${_cidcompounds}\n'
                                      'Formula: ${fetchPropertyForCompounds(_cidcompounds[index], 'MolecularFormula')}\n'
                                      'Weight: ${fetchPropertyForCompounds(_cidcompounds[index], 'molecularWeight')}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ],
            );
          }
        });
  }
}
