import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class DanbooruTag {
  final String tag;
  final int count;
  final String typeName;
  final bool isFavorite;
  final List<String> examplePaths;

  DanbooruTag({
    required this.tag,
    required this.count,
    this.typeName = 'general',
    this.isFavorite = false,
    this.examplePaths = const [],
  });

  DanbooruTag copyWith({
    String? tag,
    int? count,
    String? typeName,
    bool? isFavorite,
    List<String>? examplePaths,
  }) {
    return DanbooruTag(
      tag: tag ?? this.tag,
      count: count ?? this.count,
      typeName: typeName ?? this.typeName,
      isFavorite: isFavorite ?? this.isFavorite,
      examplePaths: examplePaths ?? this.examplePaths,
    );
  }

  factory DanbooruTag.fromJson(Map<String, dynamic> json) {
    return DanbooruTag(
      tag: json['tag'] as String,
      count: json['count'] as int,
      typeName: json['type_name'] as String? ?? 'general',
      isFavorite: json['is_favorite'] as bool? ?? false,
      examplePaths: (json['example_paths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'count': count,
      'type_name': typeName,
      'is_favorite': isFavorite,
      'example_paths': examplePaths,
    };
  }
}

class TagService {
  final String filePath;
  List<DanbooruTag> _tags = [];
  bool _isLoaded = false;
  Set<String>? _tagSet;

  Set<String> get tagSet {
    _tagSet ??= _tags.map((t) => t.tag.toLowerCase()).toSet();
    return _tagSet!;
  }

  bool hasTag(String tag) => tagSet.contains(tag.toLowerCase().trim());

  TagService({required this.filePath});

  bool get isLoaded => _isLoaded;
  List<DanbooruTag> get tags => _tags;

  Future<void> loadTags() async {
    try {
      if (kIsWeb) {
        final content = await rootBundle.loadString('Tags/high-frequency-tags-list.json');
        _tags = await compute(_parseTags, content);
        _tags.sort((a, b) => b.count.compareTo(a.count));
        _tagSet = null;
        _isLoaded = true;
        return;
      }
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint("Tag file not found: $filePath");
        return;
      }

      // Using compute for heavy JSON parsing to keep UI responsive
      _tags = await compute(_parseTags, await file.readAsString());
      
      // Sort tags by count descending for faster suggestion ranking
      _tags.sort((a, b) => b.count.compareTo(a.count));
      
      _tagSet = null;
      _isLoaded = true;
      debugPrint("Loaded ${_tags.length} tags.");
    } catch (e) {
      debugPrint("Error loading tags: $e");
    }
  }

  static List<DanbooruTag> _parseTags(String jsonString) {
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((item) => DanbooruTag.fromJson(item)).toList();
  }

  List<DanbooruTag> getSuggestions(String query, {int limit = 20}) {
    if (!_isLoaded || query.length < 3) return [];

    final lowercaseQuery = query.toLowerCase();

    // Match tags that start with the query OR contain a word starting with it
    final List<DanbooruTag> prefixMatches = [];
    final List<DanbooruTag> wordMatches = [];

    for (final tag in _tags) {
      final lowerTag = tag.tag.toLowerCase();
      if (lowerTag.startsWith(lowercaseQuery)) {
        prefixMatches.add(tag);
      } else if (lowerTag.contains(lowercaseQuery)) {
        wordMatches.add(tag);
      }
    }

    // Sort each group: favorites first, then by count
    int compareTag(DanbooruTag a, DanbooruTag b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return b.count.compareTo(a.count);
    }

    prefixMatches.sort(compareTag);
    wordMatches.sort(compareTag);

    // Prefix matches first, then word matches
    return [...prefixMatches, ...wordMatches].take(limit).toList();
  }

  List<DanbooruTag> getTagsByCategory(String query, String category, {int limit = 20}) {
    if (!_isLoaded) return [];

    final lowerCategory = category.toLowerCase();
    final lowerQuery = query.toLowerCase();

    // Empty query → return all favorites in this category, sorted by count
    if (lowerQuery.isEmpty) {
      return _tags
          .where((tag) => tag.isFavorite && tag.typeName.toLowerCase() == lowerCategory)
          .toList();
    }

    // Non-empty query → prefix/contains matching within category, favorites first
    final List<DanbooruTag> prefixMatches = [];
    final List<DanbooruTag> wordMatches = [];

    for (final tag in _tags) {
      if (tag.typeName.toLowerCase() != lowerCategory) continue;
      final lowerTag = tag.tag.toLowerCase();
      if (lowerTag.startsWith(lowerQuery)) {
        prefixMatches.add(tag);
      } else if (lowerTag.contains(lowerQuery)) {
        wordMatches.add(tag);
      }
    }

    int compareTag(DanbooruTag a, DanbooruTag b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return b.count.compareTo(a.count);
    }

    prefixMatches.sort(compareTag);
    wordMatches.sort(compareTag);

    return [...prefixMatches, ...wordMatches].take(limit).toList();
  }

  List<DanbooruTag> getFavorites({String? category}) {
    if (!_isLoaded) return [];
    
    return _tags.where((tag) {
      final isFav = tag.isFavorite;
      if (category == null) return isFav;
      return isFav && tag.typeName.toLowerCase() == category.toLowerCase();
    }).toList();
  }

  Future<void> toggleFavorite(DanbooruTag tag) async {
    final index = _tags.indexWhere((t) => t.tag == tag.tag);
    if (index != -1) {
      _tags[index] = _tags[index].copyWith(isFavorite: !_tags[index].isFavorite);
      await saveTags();
    }
  }

  Future<void> addTag(DanbooruTag tag) async {
    _tags.add(tag);
    _tags.sort((a, b) => b.count.compareTo(a.count));
    await saveTags();
  }

  Future<void> deleteTag(DanbooruTag tag) async {
    _tags.removeWhere((t) => t.tag == tag.tag);
    await saveTags();
  }

  Future<void> addExampleToTag(String tagName, String path) async {
    final index = _tags.indexWhere((t) => t.tag == tagName);
    if (index != -1) {
      final updatedPaths = List<String>.from(_tags[index].examplePaths)
        ..add(path);
      _tags[index] = _tags[index].copyWith(examplePaths: updatedPaths);
      await saveTags();
    }
  }

  Future<void> removeExampleFromTag(String tagName, String path) async {
    final index = _tags.indexWhere((t) => t.tag == tagName);
    if (index != -1) {
      final updatedPaths = List<String>.from(_tags[index].examplePaths)
        ..remove(path);
      _tags[index] = _tags[index].copyWith(examplePaths: updatedPaths);
      await saveTags();
    }
  }

  Future<void> clearAllExamples() async {
    for (int i = 0; i < _tags.length; i++) {
      if (_tags[i].examplePaths.isNotEmpty) {
        _tags[i] = _tags[i].copyWith(examplePaths: []);
      }
    }
    await saveTags();
  }

  Future<void> saveTags() async {
    try {
      final file = File(filePath);
      final jsonString = await compute(_serializeTags, _tags);
      await file.writeAsString(jsonString);
      debugPrint("Saved ${_tags.length} tags to $filePath");
    } catch (e) {
      debugPrint("Error saving tags: $e");
    }
  }

  static String _serializeTags(List<DanbooruTag> tags) {
    return jsonEncode(tags.map((t) => t.toJson()).toList());
  }
}
