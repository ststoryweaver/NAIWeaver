import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class WildcardProcessor {
  final String wildcardDir;
  final Random _random = Random();

  WildcardProcessor({required this.wildcardDir});

  Future<String> process(String prompt) async {
    String processedPrompt = prompt;
    bool hasChanged = true;
    int depth = 0;
    const int maxDepth = 5;

    while (hasChanged && depth < maxDepth) {
      hasChanged = false;
      final matches = RegExp(r'__([a-zA-Z0-9_-]+)__').allMatches(processedPrompt).toList();
      
      if (matches.isEmpty) break;

      // Process matches from end to start to avoid index shifts
      for (final match in matches.reversed) {
        final wildcardName = match.group(1);
        if (wildcardName == null) continue;

        final replacement = await _getWildcardReplacement(wildcardName);
        if (replacement != null) {
          processedPrompt = processedPrompt.replaceRange(match.start, match.end, replacement);
          hasChanged = true;
        }
      }
      depth++;
    }

    return processedPrompt;
  }

  Future<String?> _getWildcardReplacement(String name) async {
    try {
      final resolved = p.normalize(p.join(wildcardDir, '$name.txt'));
      if (!p.isWithin(wildcardDir, resolved)) return null;
      final file = File(resolved);
      if (await file.exists()) {
        final lines = await file.readAsLines();
        final validLines = lines.where((l) => l.trim().isNotEmpty).toList();
        
        if (validLines.isNotEmpty) {
          return validLines[_random.nextInt(validLines.length)].trim();
        }
      }
    } catch (e) {
      debugPrint('Error reading wildcard $name: $e');
    }
    return null;
  }
}
