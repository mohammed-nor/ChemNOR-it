import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CompoundFinder {
  final String genAiApiKey;
  final String chempubBaseUrl = 'https://pubchem.ncbi.nlm.nih.gov/rest/pug';

  CompoundFinder({required this.genAiApiKey});
  String text = "";

  Future<String> getCompoundsFromDescription(String description) async {
    try {
      // Step 1: Get molecules from Generative AI
      final List<int> cids = await _getCidsFromAI(description);

      // Step 2: Fetch properties for each CID
      final List<Map<String, dynamic>> results = [];

      for (int cid in cids) {
        try {
          final properties = await _getCompoundProperties(cid);
          results.add(properties);
        } catch (e) {
          results.add({'error': 'Failed to fetch properties for CAS $cid'});
        }
      }

      // Step 3: Format results as plain text
      return _formatResultsAsText(results);
    } catch (e) {
      return 'Error processing request: $e';
    }
  }

  Future<List<int>> _getCidsFromAI(String description) async {
    String prompt = '''
    Given the following description: "${description}",
    try to understand the type of functional groups that is asked , 
    then provide 10 chemical compounds that match this description and have those functional groups. 
    For each compound, provide only the CID (PubChem Compound ID) 
    in this exact format: CID:12345678. Do not include any other text or formatting.
    ''';

    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: genAiApiKey,
    );

    final response = await model.generateContent([Content.text(prompt)]);
    text = response.text ?? '';

    // Extract CIDs from the response using regex
    final cidRegExp = RegExp(r'CID:(\d+)');
    final matches = cidRegExp.allMatches(text);

    if (matches.isEmpty) throw Exception('No CIDs found in AI response');

    return matches.map((match) => int.parse(match.group(1)!)).take(10).toList();
  }

  Future<Map<String, dynamic>> _getCompoundProperties(int cid) async {
    final url = Uri.parse('$chempubBaseUrl/compound/cid/$cid/JSON');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch properties for CID $cid');
    }

    final data = jsonDecode(response.body);
    final properties = data['PC_Compounds'][0]['props'];

    return {
      'cid': cid,
      'iupacName': _findProperty(properties, 'IUPAC Name'),
      'molecularFormula': _findProperty(properties, 'Molecular Formula'),
      'molecularWeight': _findProperty(properties, 'Molecular Weight'),
      'solubility': _findProperty(properties, 'Solubility'),
      'Complexity': _findProperty(properties, 'Complexity'),
      'Hydrogen Bond Donor Count':
          _findProperty(properties, 'Hydrogen Bond Donor Count'),
      'Hydrogen Bond Acceptor Count':
          _findProperty(properties, 'Hydrogen Bond Acceptor Count'),
    };
  }

  String _findProperty(List<dynamic> properties, String name) {
    try {
      final prop = properties.firstWhere(
        (p) => p['urn']['label'] == name,
        orElse: () => null,
      );
      return prop['value']['sval'] ?? prop['value']['fval'].toString();
    } catch (e) {
      return 'Not available';
    }
  }

  String _formatResultsAsText(List<Map<String, dynamic>> results) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    buffer.writeln('Compound Analysis Results');
    buffer.writeln('Generated at: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('====================================================');

    for (final result in results) {
      if (result.containsKey('error')) {
        buffer.writeln('Error: ${result['error']}');
        continue;
      }

      buffer.writeln('CID: ${result['cid']}');
      buffer.writeln('IUPAC Name: ${result['iupacName']}');
      buffer.writeln('Molecular Formula: ${result['molecularFormula']}');
      buffer.writeln('Molecular Weight: ${result['molecularWeight']} g/mol');
      buffer.writeln('Solubility: ${result['solubility']}');
      buffer.writeln('Complexity: ${result['Complexity']}');
      buffer.writeln(
          'Hydrogen Bond Donor Count: ${result['Hydrogen Bond Donor Count']}');
      buffer.writeln(
          'Hydrogen Bond Acceptor Count: ${result['Hydrogen Bond Acceptor Count']}');
      buffer.writeln('--------------------------------------------');
    }

    return '${buffer.toString()} ' + '    ' + '${text.toString()}';
  }
}
