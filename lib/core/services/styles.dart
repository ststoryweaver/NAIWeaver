import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'kv_store.dart';

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
  static const String _prefsKey = 'saved_prompt_styles';

  static Future<List<PromptStyle>> loadStyles(String filePath) async {
    try {
      final stored = await KvStore.readString(
        path: filePath,
        prefsKey: _prefsKey,
      );
      if (stored != null) {
        final List<dynamic> jsonList = jsonDecode(stored);
        return jsonList.map((j) => PromptStyle.fromJson(j)).toList();
      }

      // First run (or web with nothing saved): seed from bundled asset.
      final content = await rootBundle.loadString('prompt_styles.json');
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => PromptStyle.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error loading styles: $e');
    }

    return [
      PromptStyle(
        name: "Quality V4.5 (NAI Default)",
        prefix: "best quality, amazing quality, very aesthetic, absurdres, ",
      ),
    ];
  }

  static Future<void> saveStyles(
      String filePath, List<PromptStyle> styles) async {
    try {
      final jsonString = jsonEncode(styles.map((s) => s.toJson()).toList());
      await KvStore.writeString(
        path: filePath,
        prefsKey: _prefsKey,
        value: jsonString,
      );
    } catch (e) {
      debugPrint('Error saving styles: $e');
    }
  }

  /// Resets styles to bundled defaults by overwriting saved data.
  static Future<List<PromptStyle>> resetToDefaults(String filePath) async {
    try {
      final content = await rootBundle.loadString('prompt_styles.json');
      await KvStore.writeString(
        path: filePath,
        prefsKey: _prefsKey,
        value: content,
      );
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => PromptStyle.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error resetting styles: $e');
      return [
        PromptStyle(
          name: "Quality V4.5 (NAI Default)",
          prefix: "best quality, amazing quality, very aesthetic, absurdres, ",
        ),
      ];
    }
  }
}
