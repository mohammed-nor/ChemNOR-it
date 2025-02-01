// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final String _apiKey;
  static const String _aiEndpoint =
      'https://api.openai.com/v1/chat/completions';

  AIService(this._apiKey);

  Future<InterpretedQuery> interpretQuery(String userQuery) async {
    final response = await http.post(
      Uri.parse(_aiEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '''Analyze this chemical query and extract:
            1. Primary search terms
            2. Key properties (molecular weight, solubility, etc.)
            3. Target applications
            4. Structural features
            Return JSON format with keys: searchTerms, properties, applications, structures'''
          },
          {'role': 'user', 'content': userQuery}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['choices'][0]['message']['content'];
      return InterpretedQuery.fromJson(jsonDecode(content));
    } else {
      throw Exception('AI query interpretation failed');
    }
  }
}

class ChemPubService {
  final String _apiKey;
  static const String _baseUrl = 'https://api.chempub.com/v1';

  ChemPubService(this._apiKey);

  Future<List<MoleculeResult>> searchCompounds({
    required String query,
    required List<String> properties,
    int maxResults = 10,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'query': query,
        'properties': properties.join(','),
        'max_results': maxResults.toString(),
      }),
      headers: {'Authorization': 'Bearer $_apiKey'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['results'] as List)
          .map((item) => MoleculeResult.fromJson(item))
          .toList();
    } else {
      throw Exception('ChemPub API request failed');
    }
  }
}

// models.dart
class InterpretedQuery {
  final List<String> searchTerms;
  final List<String> properties;
  final List<String> applications;
  final List<String> structures;

  InterpretedQuery({
    required this.searchTerms,
    required this.properties,
    required this.applications,
    required this.structures,
  });

  factory InterpretedQuery.fromJson(Map<String, dynamic> json) {
    return InterpretedQuery(
      searchTerms: List<String>.from(json['searchTerms']),
      properties: List<String>.from(json['properties']),
      applications: List<String>.from(json['applications']),
      structures: List<String>.from(json['structures']),
    );
  }
}

class MoleculeResult {
  final String name;
  final String smiles;
  final double molecularWeight;
  final String? bioactivity;

  MoleculeResult({
    required this.name,
    required this.smiles,
    required this.molecularWeight,
    this.bioactivity,
  });

  factory MoleculeResult.fromJson(Map<String, dynamic> json) {
    return MoleculeResult(
      name: json['name'],
      smiles: json['smiles'],
      molecularWeight: json['molecularWeight'],
      bioactivity: json['bioactivity'],
    );
  }
}
