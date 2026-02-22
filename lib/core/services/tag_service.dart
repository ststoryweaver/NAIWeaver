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
  final List<String> aliases;
  final String? matchedAlias;

  DanbooruTag({
    required this.tag,
    required this.count,
    this.typeName = 'general',
    this.isFavorite = false,
    this.examplePaths = const [],
    this.aliases = const [],
    this.matchedAlias,
  });

  DanbooruTag copyWith({
    String? tag,
    int? count,
    String? typeName,
    bool? isFavorite,
    List<String>? examplePaths,
    List<String>? aliases,
    String? Function()? matchedAlias,
  }) {
    return DanbooruTag(
      tag: tag ?? this.tag,
      count: count ?? this.count,
      typeName: typeName ?? this.typeName,
      isFavorite: isFavorite ?? this.isFavorite,
      examplePaths: examplePaths ?? this.examplePaths,
      aliases: aliases ?? this.aliases,
      matchedAlias: matchedAlias != null ? matchedAlias() : this.matchedAlias,
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
      aliases: (json['aliases'] as List<dynamic>?)
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
      'aliases': aliases,
    };
  }
}

class TagService {
  final String filePath;
  List<DanbooruTag> _tags = [];
  bool _isLoaded = false;
  Set<String>? _tagSet;
  Map<String, int>? _aliasToTagIndex;

  Set<String> get tagSet {
    _tagSet ??= _tags.map((t) => t.tag.toLowerCase()).toSet();
    return _tagSet!;
  }

  bool hasTag(String tag) => tagSet.contains(tag.toLowerCase().trim());

  /// Returns true if any codeUnit in [s] is > 127 (non-ASCII, e.g. CJK).
  static bool containsNonAscii(String s) {
    for (int i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) > 127) return true;
    }
    return false;
  }

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
        _buildAliasIndex();
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
      _buildAliasIndex();
      _isLoaded = true;
      debugPrint("Loaded ${_tags.length} tags.");
    } catch (e) {
      debugPrint("Error loading tags: $e");
    }
  }

  void _buildAliasIndex() {
    final index = <String, int>{};
    final tags = tagSet; // ensure tagSet is built
    for (int i = 0; i < _tags.length; i++) {
      for (final alias in _tags[i].aliases) {
        final lowerAlias = alias.toLowerCase();
        // English tag names always take priority over aliases
        if (!tags.contains(lowerAlias)) {
          index.putIfAbsent(lowerAlias, () => i);
        }
      }
    }
    _aliasToTagIndex = index;
  }

  static List<DanbooruTag> _parseTags(String jsonString) {
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((item) => DanbooruTag.fromJson(item)).toList();
  }

  List<DanbooruTag> getSuggestions(String query, {int limit = 20}) {
    final minLength = containsNonAscii(query) ? 1 : 3;
    if (!_isLoaded || query.length < minLength) return [];

    final lowercaseQuery = query.toLowerCase();
    final seenTags = <String>{};

    // Tier 1: English tag prefix/contains matches
    final List<DanbooruTag> prefixMatches = [];
    final List<DanbooruTag> wordMatches = [];

    for (final tag in _tags) {
      final lowerTag = tag.tag.toLowerCase();
      if (lowerTag.startsWith(lowercaseQuery)) {
        prefixMatches.add(tag);
        seenTags.add(lowerTag);
      } else if (lowerTag.contains(lowercaseQuery)) {
        wordMatches.add(tag);
        seenTags.add(lowerTag);
      }
    }

    // Tier 2: Alias prefix/contains matches
    final List<DanbooruTag> aliasMatches = [];
    if (_aliasToTagIndex != null) {
      for (final entry in _aliasToTagIndex!.entries) {
        final alias = entry.key;
        final tagIndex = entry.value;
        if (alias.startsWith(lowercaseQuery) || alias.contains(lowercaseQuery)) {
          final tag = _tags[tagIndex];
          if (!seenTags.contains(tag.tag.toLowerCase())) {
            // Find the original-cased alias for display
            final originalAlias = tag.aliases.firstWhere(
              (a) => a.toLowerCase() == alias,
              orElse: () => alias,
            );
            aliasMatches.add(tag.copyWith(matchedAlias: () => originalAlias));
            seenTags.add(tag.tag.toLowerCase());
          }
        }
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
    aliasMatches.sort(compareTag);

    return [...prefixMatches, ...wordMatches, ...aliasMatches].take(limit).toList();
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

    final seenTags = <String>{};

    // Non-empty query → prefix/contains matching within category, favorites first
    final List<DanbooruTag> prefixMatches = [];
    final List<DanbooruTag> wordMatches = [];

    for (final tag in _tags) {
      if (tag.typeName.toLowerCase() != lowerCategory) continue;
      final lowerTag = tag.tag.toLowerCase();
      if (lowerTag.startsWith(lowerQuery)) {
        prefixMatches.add(tag);
        seenTags.add(lowerTag);
      } else if (lowerTag.contains(lowerQuery)) {
        wordMatches.add(tag);
        seenTags.add(lowerTag);
      }
    }

    // Alias matches within category
    final List<DanbooruTag> aliasMatches = [];
    if (_aliasToTagIndex != null) {
      for (final entry in _aliasToTagIndex!.entries) {
        final alias = entry.key;
        final tagIndex = entry.value;
        if (alias.startsWith(lowerQuery) || alias.contains(lowerQuery)) {
          final tag = _tags[tagIndex];
          if (tag.typeName.toLowerCase() != lowerCategory) continue;
          if (!seenTags.contains(tag.tag.toLowerCase())) {
            final originalAlias = tag.aliases.firstWhere(
              (a) => a.toLowerCase() == alias,
              orElse: () => alias,
            );
            aliasMatches.add(tag.copyWith(matchedAlias: () => originalAlias));
            seenTags.add(tag.tag.toLowerCase());
          }
        }
      }
    }

    int compareTag(DanbooruTag a, DanbooruTag b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return b.count.compareTo(a.count);
    }

    prefixMatches.sort(compareTag);
    wordMatches.sort(compareTag);
    aliasMatches.sort(compareTag);

    return [...prefixMatches, ...wordMatches, ...aliasMatches].take(limit).toList();
  }

  /// Resolves alias text in a prompt to English Danbooru tag names.
  ///
  /// Splits on `,` and `|`, preserves delimiters and whitespace,
  /// strips weight brackets before lookup, re-wraps after.
  String resolveAliases(String prompt) {
    if (!_isLoaded || _aliasToTagIndex == null || prompt.isEmpty) return prompt;

    final buffer = StringBuffer();
    final segmentPattern = RegExp(r'[,|]');
    int start = 0;

    while (start < prompt.length) {
      final match = segmentPattern.matchAsPrefix(prompt, start) ??
          _findNextDelimiter(prompt, start, segmentPattern);

      final int segEnd;
      final String? delimiter;
      if (match != null && match.start == start) {
        // Current position is a delimiter
        buffer.write(prompt[start]);
        start++;
        continue;
      }

      // Find next delimiter
      final nextDelim = segmentPattern.firstMatch(prompt.substring(start));
      if (nextDelim != null) {
        segEnd = start + nextDelim.start;
        delimiter = prompt[segEnd];
      } else {
        segEnd = prompt.length;
        delimiter = null;
      }

      final segment = prompt.substring(start, segEnd);
      buffer.write(_resolveSegment(segment));
      if (delimiter != null) buffer.write(delimiter);
      start = segEnd + (delimiter != null ? 1 : 0);
    }

    return buffer.toString();
  }

  Match? _findNextDelimiter(String prompt, int start, RegExp pattern) {
    final sub = prompt.substring(start);
    return pattern.firstMatch(sub);
  }

  String _resolveSegment(String segment) {
    // Preserve leading/trailing whitespace
    final leading = segment.length - segment.trimLeft().length;
    final trailing = segment.length - segment.trimRight().length;
    final leadingWs = segment.substring(0, leading);
    final trailingWs = trailing > 0 ? segment.substring(segment.length - trailing) : '';
    final trimmed = segment.trim();
    if (trimmed.isEmpty) return segment;

    // Strip weight brackets from both ends
    String core = trimmed;
    String prefixBrackets = '';
    String suffixBrackets = '';
    while (core.isNotEmpty && (core[0] == '{' || core[0] == '[')) {
      prefixBrackets += core[0];
      core = core.substring(1);
    }
    while (core.isNotEmpty && (core[core.length - 1] == '}' || core[core.length - 1] == ']')) {
      suffixBrackets = core[core.length - 1] + suffixBrackets;
      core = core.substring(0, core.length - 1);
    }
    core = core.trim();
    if (core.isEmpty) return segment;

    final lowerCore = core.toLowerCase();

    // If it's already a known English tag, pass through
    if (tagSet.contains(lowerCore)) return segment;

    // If it's a known alias, replace with English tag
    final tagIndex = _aliasToTagIndex![lowerCore];
    if (tagIndex != null) {
      final englishTag = _tags[tagIndex].tag;
      return '$leadingWs$prefixBrackets$englishTag$suffixBrackets$trailingWs';
    }

    return segment;
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
