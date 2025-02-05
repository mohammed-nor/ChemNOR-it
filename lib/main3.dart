import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chem_nor/chem_nor.dart';

void main() async {
  final finder =
      ChemNOR(genAiApiKey: 'AIzaSyCR80a7Gb4kSGd5rX9ingZhJKSw9b9hQgQ');
  final results = await finder.findCompounds('carboxylic acid');
  print(results);
  /*String? _findProperty(List<dynamic> properties, String label) {
    try {
      final prop = properties.firstWhere(
        (p) => p['urn']['label'] == label,
        orElse: () => null,
      );
      return prop['value']['sval'] ?? prop['value']['fval'].toString();
    } catch (e) {
      return null;
    }
  }

  String? _findfvalPropertybylabel(
      List<dynamic> properties, String name, String label) {
    try {
      final prop = properties.firstWhere(
        (p) => p['urn']['name'] == name && p['urn']['label'] == label,
        orElse: () => null,
      );
      return prop['value']['sval'] ?? prop['value']['fval'].toString();
    } catch (e) {
      return null;
    }
  }

  String? _findivalPropertybylabel(
      List<dynamic> properties, String name, String label) {
    try {
      final prop = properties.firstWhere(
        (p) => p['urn']['name'] == name && p['urn']['label'] == label,
        orElse: () => null,
      );
      return prop['value']['sval'] ?? prop['value']['ival'].toString();
    } catch (e) {
      return null;
    }
  }

  String? _findfvalPropertybylabelonly(List<dynamic> properties, String label) {
    try {
      final prop = properties.firstWhere(
        (p) => p['urn']['label'] == label,
        orElse: () => null,
      );
      return prop['value']['sval'] ?? prop['value']['fval'].toString();
    } catch (e) {
      return null;
    }
  }

  final url = Uri.parse(
      'https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/2244/JSON');
  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch properties for CID ');
  }

  final data = jsonDecode(response.body);
  final properties = data['PC_Compounds'][0]['props'];

  print(properties);
  print(_findfvalPropertybylabel(properties, 'Absolute', 'SMILES') ??
      'Unnamed compound');
  print(_findProperty(properties, 'Molecular Formula') ?? 'Unnamed compound');
  print(_findfvalPropertybylabelonly(properties, 'Molecular Weight') ??
      'Unnamed compound');
  print(_findfvalPropertybylabel(properties, 'Allowed', 'IUPAC Name') ??
      'Unnamed compound');
  print(_findivalPropertybylabel(properties, 'Hydrogen Bond Donor', 'Count') ??
      'Unnamed compound');
  print(
      _findivalPropertybylabel(properties, 'Hydrogen Bond Acceptor', 'Count') ??
          'Unnamed compound');
  print(_findivalPropertybylabel(properties, 'Rotatable Bond', 'Count') ??
      'Unnamed compound');
  print(_findfvalPropertybylabel(
          properties, 'Polar Surface Area', 'Topological') ??
      'Unnamed compound');
  print(_findfvalPropertybylabelonly(properties, 'Compound Complexity') ??
      'Unnamed compound');

  print(_findfvalPropertybylabel(properties, 'XLogP3', 'Log P') ??
      'Unnamed compound');*/
}
