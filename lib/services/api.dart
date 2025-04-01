import 'dart:convert';
import 'package:http/http.dart' as http;



// List of CIDs (Replace with your own)
const List<int> cids = [2244, 236, 23925, 178];

// Model for Compound Data
class Compound {
  final int cid;
  final String name;
  final String molecularFormula;
  final double molecularWeight;

  Compound({
    required this.cid,
    required this.name,
    required this.molecularFormula,
    required this.molecularWeight,
  });

  // Factory constructor to create a Compound object from JSON
  factory Compound.fromJson(int cid, Map<String, dynamic> json) {
    return Compound(
      cid: cid,
      name: json["IUPACName"] ?? "Unknown",
      molecularFormula: json["MolecularFormula"] ?? "N/A",
      molecularWeight: (json["MolecularWeight"] != null) ? double.tryParse(json["MolecularWeight"]) ?? 0.0 : 0.0,
    );
  }
}

// Function to fetch compound data
Future<List<Compound>> fetchCompounds(List<int> cids) async {
  List<Compound> compounds = [];

  for (int cid in cids) {
    final url = "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$cid/property/IUPACName,MolecularFormula,MolecularWeight/JSON";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final properties = data["PropertyTable"]["Properties"][0];
        compounds.add(Compound.fromJson(cid, properties));
      } else {
        print("Error fetching CID $cid: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception for CID $cid: $e");
    }
  }
  return compounds;
}

Future<String> fetchPropertyForCompounds(int cid, String property) async {
  var compounds = [];
  String compound = '';
  var data;

  final url = "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/$cid/$property/property/JSON";

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final properties = data["PropertyTable"][property][0];
      compound = Compound.fromJson(cid, properties).toString();
      return data;
    } else {
      print("Error fetching CID $cid: ${response.statusCode}");
      return data;
    }
  } catch (e) {
    print("Exception for CID $cid: $e");
  }
  return data;
}
