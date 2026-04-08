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
    
    // Auto inject import if not present
    if (!content.contains("import 'package:chemnor_it/main.dart';")) {
      content = content.replaceFirst(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:chemnor_it/main.dart';"
      );
    }
    
    // Add final fontSize if needed (basic heuristic)
    // We can replace `Widget build(BuildContext context) {` with `Widget build(BuildContext context) {\n    final fontSize = settingsController.value.fontSize;`
    // but we only want to do it once per build method.
    // Let's use a regex that matches `Widget build(BuildContext context) {` and checks for fontSize
    content = content.splitMapJoin(
      RegExp(r'Widget build\(BuildContext context\)\s*\{'),
      onMatch: (m) => '${m.group(0)}\n    final _baseFontSize = settingsController.value.fontSize;',
      onNonMatch: (n) => n
    );

    // Replace all fontSize: \d+ with fontSize: _baseFontSize + diff
    content = content.replaceAllMapped(RegExp(r'fontSize:\s*(\d+)(\.\d+)?'), (match) {
      final sizeStr = match.group(1)!;
      final size = double.parse(sizeStr);
      if (size == 14) return 'fontSize: _baseFontSize';
      double diff = size - 14;
      if (diff > 0) return 'fontSize: _baseFontSize + $diff';
      return 'fontSize: _baseFontSize - ${diff.abs()}';
    });

    File(file).writeAsStringSync(content);
    print('Updated $file');
  }
}
