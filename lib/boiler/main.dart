// Initialize with your Google AI API key
import 'package:ChemNOR_it/boiler/services.dart';
import 'package:http/http.dart' as http;

void main() async {
  final compoundFinder =
      CompoundFinder(genAiApiKey: 'AIzaSyCR80a7Gb4kSGd5rX9ingZhJKSw9b9hQgQ');

// Get results for a description
  final results = await compoundFinder
      .getCompoundsFromDescription(' a molecule SOLLUBLE IN WATER');

  print(results);
  // Additional data source example using Cactus NCI
  Future<String> getSmilesFromCactus(String cas) async {
    final response = await http.get(
        Uri.parse('https://cactus.nci.nih.gov/chemical/structure/$cas/smiles'));
    return response.body;
  }
}
