import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../tag_service.dart';

class TagPreviewSettings {
  final String positivePrompt;
  final String negativePrompt;
  final double width;
  final double height;
  final double scale;
  final int steps;
  final String sampler;
  final int? seed;

  TagPreviewSettings({
    this.positivePrompt = "1girl",
    this.negativePrompt =
        "nsfw, lowres, artistic error, scan artifacts, worst quality, bad quality, jpeg artifacts, multiple views, very displeasing, too many watermarks, negative space, blank page",
    this.width = 832,
    this.height = 1216,
    this.scale = 6.0,
    this.steps = 28,
    this.sampler = "k_euler_ancestral",
    this.seed,
  });

  TagPreviewSettings copyWith({
    String? positivePrompt,
    String? negativePrompt,
    double? width,
    double? height,
    double? scale,
    int? steps,
    String? sampler,
    int? seed,
    bool clearSeed = false,
  }) {
    return TagPreviewSettings(
      positivePrompt: positivePrompt ?? this.positivePrompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      width: width ?? this.width,
      height: height ?? this.height,
      scale: scale ?? this.scale,
      steps: steps ?? this.steps,
      sampler: sampler ?? this.sampler,
      seed: clearSeed ? null : (seed ?? this.seed),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'positivePrompt': positivePrompt,
      'negativePrompt': negativePrompt,
      'width': width,
      'height': height,
      'scale': scale,
      'steps': steps,
      'sampler': sampler,
      'seed': seed,
    };
  }

  factory TagPreviewSettings.fromJson(Map<String, dynamic> json) {
    return TagPreviewSettings(
      positivePrompt: json['positivePrompt'] ?? "1girl",
      negativePrompt: json['negativePrompt'] ??
          "nsfw, lowres, artistic error, scan artifacts, worst quality, bad quality, jpeg artifacts, multiple views, very displeasing, too many watermarks, negative space, blank page",
      width: (json['width'] as num?)?.toDouble() ?? 832,
      height: (json['height'] as num?)?.toDouble() ?? 1216,
      scale: (json['scale'] as num?)?.toDouble() ?? 6.0,
      steps: json['steps'] ?? 28,
      sampler: json['sampler'] ?? "k_euler_ancestral",
      seed: json['seed'],
    );
  }
}

enum TagSort {
  countDesc,
  countAsc,
  alphaAsc,
  alphaDesc,
  favoritesFirst,
}

class TagLibraryState {
  final List<DanbooruTag> tags;
  final String searchQuery;
  final String? selectedCategory;
  final bool showFavoritesOnly;
  final bool showWithExamplesOnly;
  final TagSort sort;
  final bool isLoading;
  final TagPreviewSettings previewSettings;

  TagLibraryState({
    this.tags = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.showFavoritesOnly = false,
    this.showWithExamplesOnly = false,
    this.sort = TagSort.countDesc,
    this.isLoading = false,
    TagPreviewSettings? previewSettings,
  }) : previewSettings = previewSettings ?? TagPreviewSettings();

  TagLibraryState copyWith({
    List<DanbooruTag>? tags,
    String? searchQuery,
    String? selectedCategory,
    bool clearCategory = false,
    bool? showFavoritesOnly,
    bool? showWithExamplesOnly,
    TagSort? sort,
    bool? isLoading,
    TagPreviewSettings? previewSettings,
  }) {
    return TagLibraryState(
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      showWithExamplesOnly: showWithExamplesOnly ?? this.showWithExamplesOnly,
      sort: sort ?? this.sort,
      isLoading: isLoading ?? this.isLoading,
      previewSettings: previewSettings ?? this.previewSettings,
    );
  }
}

class TagLibraryNotifier extends ChangeNotifier {
  final TagService tagService;
  final String examplesDir;
  TagLibraryState _state = TagLibraryState();
  TagLibraryState get state => _state;

  TagLibraryNotifier({required this.tagService, required this.examplesDir}) {
    _loadPreviewSettings();
    _migrateExamplesOnce();
    _refreshTags();
  }

  Future<void> _migrateExamplesOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('examples_v2_migrated') == true) return;
    await clearAllExamples();
    await prefs.setBool('examples_v2_migrated', true);
  }

  Future<void> clearAllExamples() async {
    try {
      await tagService.clearAllExamples();
      final dir = Directory(examplesDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _refreshTags();
    } catch (e) {
      debugPrint('Error clearing examples: $e');
    }
  }

  Future<void> _loadPreviewSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('tag_preview_settings');
      if (settingsJson != null) {
        final settings = TagPreviewSettings.fromJson(jsonDecode(settingsJson));
        _state = _state.copyWith(previewSettings: settings);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading preview settings: $e");
    }
  }

  Future<void> updatePreviewSettings(TagPreviewSettings settings) async {
    _state = _state.copyWith(previewSettings: settings);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'tag_preview_settings', jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint("Error saving preview settings: $e");
    }
  }

  void _refreshTags() {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    List<DanbooruTag> filteredTags = tagService.tags;

    // Filter by category
    if (_state.selectedCategory != null) {
      filteredTags = filteredTags
          .where((t) => t.typeName == _state.selectedCategory)
          .toList();
    }

    // Filter by favorites
    if (_state.showFavoritesOnly) {
      filteredTags = filteredTags.where((t) => t.isFavorite).toList();
    }

    // Filter by examples
    if (_state.showWithExamplesOnly) {
      filteredTags =
          filteredTags.where((t) => t.examplePaths.isNotEmpty).toList();
    }

    // Filter by search
    if (_state.searchQuery.isNotEmpty) {
      final query = _state.searchQuery.toLowerCase();
      filteredTags = filteredTags
          .where((t) => t.tag.toLowerCase().contains(query))
          .toList();
    }

    // Sort
    switch (_state.sort) {
      case TagSort.countDesc:
        filteredTags.sort((a, b) => b.count.compareTo(a.count));
        break;
      case TagSort.countAsc:
        filteredTags.sort((a, b) => a.count.compareTo(b.count));
        break;
      case TagSort.alphaAsc:
        filteredTags
            .sort((a, b) => a.tag.toLowerCase().compareTo(b.tag.toLowerCase()));
        break;
      case TagSort.alphaDesc:
        filteredTags
            .sort((a, b) => b.tag.toLowerCase().compareTo(a.tag.toLowerCase()));
        break;
      case TagSort.favoritesFirst:
        filteredTags.sort((a, b) {
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          return b.count.compareTo(a.count);
        });
        break;
    }

    _state = _state.copyWith(tags: filteredTags, isLoading: false);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _state = _state.copyWith(searchQuery: query);
    _refreshTags();
  }

  void setCategory(String? category) {
    if (category == null) {
      _state = _state.copyWith(clearCategory: true);
    } else {
      _state = _state.copyWith(selectedCategory: category);
    }
    _refreshTags();
  }

  void setSort(TagSort sort) {
    _state = _state.copyWith(sort: sort);
    _refreshTags();
  }

  void toggleFavoritesOnly() {
    _state = _state.copyWith(showFavoritesOnly: !_state.showFavoritesOnly);
    _refreshTags();
  }

  void toggleWithExamplesOnly() {
    _state =
        _state.copyWith(showWithExamplesOnly: !_state.showWithExamplesOnly);
    _refreshTags();
  }

  Future<void> toggleFavorite(DanbooruTag tag) async {
    await tagService.toggleFavorite(tag);
    _refreshTags();
  }

  Future<void> addTag(String tag, int count, String category) async {
    final newTag = DanbooruTag(tag: tag, count: count, typeName: category);
    await tagService.addTag(newTag);
    _refreshTags();
  }

  Future<void> deleteTag(DanbooruTag tag) async {
    await tagService.deleteTag(tag);
    _refreshTags();
  }

  Future<void> saveExample(String tagName, Uint8List bytes) async {
    try {
      final dir = Directory(examplesDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Sanitize tagName for file system
      final sanitizedTagName = tagName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${sanitizedTagName}_$timestamp.png';
      final path = '${dir.path}/$fileName';

      debugPrint("Saving example for $tagName to $path");
      await File(path).writeAsBytes(bytes);
      await tagService.addExampleToTag(tagName, path);
      debugPrint("Successfully added example to $tagName");
      _refreshTags();
    } catch (e) {
      debugPrint("Error saving example for $tagName: $e");
    }
  }

  Future<void> deleteExample(String tagName, String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await tagService.removeExampleFromTag(tagName, path);
      _refreshTags();
    } catch (e) {
      debugPrint("Error deleting example: $e");
    }
  }

  List<String> getCategories() {
    return tagService.tags.map((t) => t.typeName).toSet().toList()..sort();
  }
}
