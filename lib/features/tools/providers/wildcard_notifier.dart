import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/services/wildcard_service.dart';
import '../../../tag_service.dart';
import '../../../wildcard_processor.dart';

class WildcardState {
  final List<File> files;
  final File? selectedFile;
  final String content;
  final List<DanbooruTag> tagSuggestions;
  final String currentTagQuery;
  final bool isLoading;
  final List<String> invalidTags;
  final int validCount;

  WildcardState({
    this.files = const [],
    this.selectedFile,
    this.content = '',
    this.tagSuggestions = const [],
    this.currentTagQuery = '',
    this.isLoading = false,
    this.invalidTags = const [],
    this.validCount = 0,
  });

  WildcardState copyWith({
    List<File>? files,
    File? selectedFile,
    String? content,
    List<DanbooruTag>? tagSuggestions,
    String? currentTagQuery,
    bool? isLoading,
    List<String>? invalidTags,
    int? validCount,
  }) {
    return WildcardState(
      files: files ?? this.files,
      selectedFile: selectedFile ?? this.selectedFile,
      content: content ?? this.content,
      tagSuggestions: tagSuggestions ?? this.tagSuggestions,
      currentTagQuery: currentTagQuery ?? this.currentTagQuery,
      isLoading: isLoading ?? this.isLoading,
      invalidTags: invalidTags ?? this.invalidTags,
      validCount: validCount ?? this.validCount,
    );
  }
}

class WildcardNotifier extends ChangeNotifier {
  final String wildcardDir;
  final TagService tagService;
  final WildcardService wildcardService;

  WildcardState _state = WildcardState();
  WildcardState get state => _state;

  final TextEditingController editorController = TextEditingController();

  WildcardNotifier({
    required this.wildcardDir,
    required this.tagService,
    required this.wildcardService,
  }) {
    refreshFiles();
  }

  Future<void> refreshFiles() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final directory = Directory(wildcardDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileMap = <String, File>{};
      for (final f in directory.listSync().whereType<File>()) {
        if (p.extension(f.path) == '.txt') {
          fileMap[p.basenameWithoutExtension(f.path)] = f;
        }
      }

      // Use wildcardService.wildcardNames order (respects custom order)
      final orderedFiles = <File>[];
      for (final name in wildcardService.wildcardNames) {
        final file = fileMap[name];
        if (file != null) orderedFiles.add(file);
      }

      _state = _state.copyWith(files: orderedFiles, isLoading: false);
    } catch (e) {
      debugPrint('Error refreshing wildcards: $e');
      _state = _state.copyWith(isLoading: false);
    }
    notifyListeners();
  }

  bool isFavorite(File file) {
    return wildcardService.isFavorite(p.basenameWithoutExtension(file.path));
  }

  Future<void> toggleFavorite(File file) async {
    final name = p.basenameWithoutExtension(file.path);
    await wildcardService.toggleFavorite(name);
    await refreshFiles();
  }

  Future<void> reorderFiles(int oldIndex, int newIndex) async {
    await wildcardService.reorderWildcard(oldIndex, newIndex);
    await refreshFiles();
  }

  WildcardMode getFileMode(File file) {
    return wildcardService.getMode(p.basenameWithoutExtension(file.path));
  }

  Future<void> setFileMode(File file, WildcardMode mode) async {
    await wildcardService.setMode(p.basenameWithoutExtension(file.path), mode);
    notifyListeners();
  }

  Future<void> selectFile(File? file) async {
    if (file == null) {
      _state = _state.copyWith(selectedFile: null, content: '', invalidTags: const [], validCount: 0);
      editorController.text = '';
      notifyListeners();
      return;
    }

    try {
      final content = await file.readAsString();
      _state = _state.copyWith(selectedFile: file, content: content, invalidTags: const [], validCount: 0);
      editorController.text = content;
    } catch (e) {
      debugPrint('Error reading wildcard file: $e');
    }
    notifyListeners();
  }

  void validateCurrentFile() {
    final lines = editorController.text.split('\n');
    final invalid = <String>[];
    int valid = 0;

    for (final line in lines) {
      final tag = line.trim();
      if (tag.isEmpty) continue;
      if (tagService.hasTag(tag)) {
        valid++;
      } else {
        invalid.add(tag);
      }
    }

    _state = _state.copyWith(invalidTags: invalid, validCount: valid);
    notifyListeners();
  }

  void clearValidation() {
    _state = _state.copyWith(invalidTags: const [], validCount: 0);
    notifyListeners();
  }

  Future<void> saveCurrentFile() async {
    if (_state.selectedFile == null) return;

    try {
      await _state.selectedFile!.writeAsString(editorController.text);
      _state = _state.copyWith(content: editorController.text);
    } catch (e) {
      debugPrint('Error saving wildcard file: $e');
    }
    notifyListeners();
  }

  Future<void> createFile(String name) async {
    if (name.isEmpty) return;

    final fileName = name.endsWith('.txt') ? name : '$name.txt';
    final filePath = p.join(wildcardDir, fileName);
    final file = File(filePath);

    if (await file.exists()) {
      debugPrint('File already exists');
      return;
    }

    try {
      await file.writeAsString('');
      await wildcardService.refresh();
      await refreshFiles();
      final newFile = _state.files.firstWhere((f) => p.basename(f.path) == fileName);
      await selectFile(newFile);
    } catch (e) {
      debugPrint('Error creating wildcard file: $e');
    }
  }

  Future<void> deleteFile(File file) async {
    try {
      if (_state.selectedFile?.path == file.path) {
        _state = _state.copyWith(selectedFile: null, content: '');
        editorController.text = '';
      }
      await file.delete();
      await wildcardService.refresh();
      await refreshFiles();
    } catch (e) {
      debugPrint('Error deleting wildcard file: $e');
    }
  }

  void handleTagSuggestions(String text, TextSelection selection) {
    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _state = _state.copyWith(tagSuggestions: []);
      notifyListeners();
      return;
    }

    final cursorPosition = selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPosition);

    // Support both commas and line breaks as separators
    final lastDelimiter = beforeCursor.lastIndexOf(RegExp(r'[,|\n]'));
    final currentWord = beforeCursor.substring(lastDelimiter + 1).trimLeft();

    if (currentWord.length >= 3) {
      final suggestions = tagService.getSuggestions(currentWord);
      _state = _state.copyWith(
        currentTagQuery: currentWord,
        tagSuggestions: suggestions,
      );
    } else {
      _state = _state.copyWith(tagSuggestions: [], currentTagQuery: "");
    }
    notifyListeners();
  }

  void clearTagSuggestions() {
    if (_state.tagSuggestions.isEmpty) return;
    _state = _state.copyWith(tagSuggestions: [], currentTagQuery: "");
    notifyListeners();
  }

  void applyTagSuggestion(DanbooruTag tag) {
    final text = editorController.text;
    final selection = editorController.selection;
    final cursorPosition = selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);

    final lastDelimiterIndex = beforeCursor.lastIndexOf(RegExp(r'[,|\n]'));
    final prefix = beforeCursor.substring(0, lastDelimiterIndex + 1);

    // Determine if we should add a comma or just the tag (if it's a new line)
    String separator = '';
    if (lastDelimiterIndex != -1) {
      final lastChar = beforeCursor[lastDelimiterIndex];
      if (lastChar == ',') separator = ' ';
    }

    final newBeforeCursor = "$prefix$separator${tag.tag}\n";
    editorController.value = TextEditingValue(
      text: newBeforeCursor + afterCursor,
      selection: TextSelection.collapsed(offset: newBeforeCursor.length),
    );

    _state = _state.copyWith(tagSuggestions: [], currentTagQuery: "");
    saveCurrentFile();
    notifyListeners();
  }

  @override
  void dispose() {
    editorController.dispose();
    super.dispose();
  }
}
