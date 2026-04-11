import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _storageKey = 'saved_prompt_styles';

  static Future<List<PromptStyle>> loadStyles(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedStyles = prefs.getString(_storageKey);
      if (storedStyles != null && storedStyles.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(storedStyles);
        return jsonList.map((j) => PromptStyle.fromJson(j)).toList();
      }

      final content = await rootBundle.loadString('prompt_styles.json');
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => PromptStyle.fromJson(j)).toList();
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
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(styles.map((s) => s.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving styles: $e');
    }
  }

  /// Resets styles to bundled defaults by saving default content to SharedPreferences.
  static Future<List<PromptStyle>> resetToDefaults(String filePath) async {
    try {
      final content = await rootBundle.loadString('prompt_styles.json');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, content);
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => PromptStyle.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error resetting styles: $e');
      return [
        PromptStyle(
          name: "Quality (NAI Default)",
          prefix: "best quality, amazing quality, very aesthetic, absurdres, ",
        ),
      ];
    }
  }
}
