import 'dart:io';

void main() {
  final files = [
    'lib/screens/chat.dart',
    'lib/screens/history.dart',
    'lib/screens/search.dart',
    'lib/screens/setting.dart'
  ];

  for (final file in files) {
    var content = File(file).readAsStringSync();
    
    // Replace const keywords because font sizes are now dynamic
    content = content.replaceAll('const TextSpan', 'TextSpan');
    content = content.replaceAll('const TextStyle', 'TextStyle');
    content = content.replaceAll('const Text(', 'Text(');
    content = content.replaceAll('const <TextSpan>', '<TextSpan>');
    content = content.replaceAll('const [', '['); // for children arrays that became non-const
    content = content.replaceAll('const Padding', 'Padding');
    content = content.replaceAll('const Row', 'Row');
    content = content.replaceAll('const Column', 'Column');
    content = content.replaceAll('const Icon', 'Icon');
    content = content.replaceAll('const Expanded', 'Expanded');
    content = content.replaceAll('const Container', 'Container');
    
    File(file).writeAsStringSync(content);
    print('Updated $file');
  }
}
