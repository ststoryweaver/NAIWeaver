import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class PromptStyle {
  final String name;
  final String prefix;
  final String suffix;
  final String negativeContent;
  final bool isDefault;

  PromptStyle({
    required this.name,
    this.prefix = "",
    this.suffix = "",
    this.negativeContent = "",
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'prefix': prefix,
        'suffix': suffix,
        'negativeContent': negativeContent,
        'isDefault': isDefault,
      };

  factory PromptStyle.fromJson(Map<String, dynamic> json) => PromptStyle(
        name: json['name'],
        prefix: json['prefix'] ?? "",
        suffix: json['suffix'] ?? "",
        negativeContent: json['negativeContent'] ?? "",
        isDefault: json['isDefault'] ?? false,
      );
}

class StyleStorage {
  static Future<List<PromptStyle>> loadStyles(String filePath) async {
    try {
      if (kIsWeb) {
        final content = await rootBundle.loadString('prompt_styles.json');
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((j) => PromptStyle.fromJson(j)).toList();
      }
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((j) => PromptStyle.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Error loading styles: $e');
    }

    // Default styles if file doesn't exist or error occurs
    return [
      PromptStyle(
        name: "Quality (NAI Default)",
        prefix: "best quality, amazing quality, very aesthetic, absurdres, ",
      ),
    ];
  }

  static Future<void> saveStyles(String filePath, List<PromptStyle> styles) async {
    try {
      final file = File(filePath);
      final jsonString = jsonEncode(styles.map((s) => s.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving styles: $e');
    }
  }
}
