import 'package:flutter/material.dart';
import '../../../core/services/wildcard_service.dart';
import '../../../core/utils/tag_suggestion_helper.dart';
import '../../../core/services/styles.dart';
import '../../../core/services/tag_service.dart';

class StyleState {
  final List<PromptStyle> styles;
  final PromptStyle? selectedStyle;
  final String? originalName;
  final List<DanbooruTag> tagSuggestions;
  final String currentTagQuery;
  final bool isModified;
  final bool isEditingNegative;

  StyleState({
    this.styles = const [],
    this.selectedStyle,
    this.originalName,
    this.tagSuggestions = const [],
    this.currentTagQuery = "",
    this.isModified = false,
    this.isEditingNegative = false,
  });

  StyleState copyWith({
    List<PromptStyle>? styles,
    PromptStyle? selectedStyle,
    String? originalName,
    List<DanbooruTag>? tagSuggestions,
    String? currentTagQuery,
    bool? isModified,
    bool? isEditingNegative,
  }) {
    return StyleState(
      styles: styles ?? this.styles,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      originalName: originalName ?? this.originalName,
      tagSuggestions: tagSuggestions ?? this.tagSuggestions,
      currentTagQuery: currentTagQuery ?? this.currentTagQuery,
      isModified: isModified ?? this.isModified,
      isEditingNegative: isEditingNegative ?? this.isEditingNegative,
    );
  }
}

class StyleNotifier extends ChangeNotifier {
  StyleState _state = StyleState();
  StyleState get state => _state;

  final TagService _tagService;
  final WildcardService _wildcardService;
  final String _stylesFilePath;
  final VoidCallback onStylesChanged;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  StyleNotifier({
    required TagService tagService,
    required WildcardService wildcardService,
    required List<PromptStyle> initialStyles,
    required String stylesFilePath,
    required this.onStylesChanged,
  }) : _tagService = tagService,
       _wildcardService = wildcardService,
       _stylesFilePath = stylesFilePath {
    _state = _state.copyWith(styles: initialStyles);
  }

  void selectStyle(PromptStyle? style) {
    _state = _state.copyWith(
      selectedStyle: style,
      originalName: style?.name,
      isModified: false,
      isEditingNegative: style != null && style.negativeContent.isNotEmpty && style.prefix.isEmpty && style.suffix.isEmpty,
      tagSuggestions: [],
    );
    
    if (style != null) {
      nameController.text = style.name;
      _updateContentController();
    } else {
      nameController.clear();
      contentController.clear();
    }
    notifyListeners();
  }

  void setEditingNegative(bool value) {
    _state = _state.copyWith(isEditingNegative: value);
    _updateContentController();
    notifyListeners();
  }

  void _updateContentController() {
    if (_state.selectedStyle == null) return;
    
    if (_state.isEditingNegative) {
      contentController.text = _state.selectedStyle!.negativeContent;
    } else {
      contentController.text = _state.selectedStyle!.prefix.isNotEmpty 
          ? _state.selectedStyle!.prefix 
          : _state.selectedStyle!.suffix;
    }
  }

  void updateCurrentStyle({
    String? name,
    String? content,
    bool? isPrefix,
    bool? isDefault,
  }) {
    if (_state.selectedStyle == null) return;

    final finalContent = content ?? contentController.text;
    
    PromptStyle updated;
    if (_state.isEditingNegative) {
      updated = PromptStyle(
        name: name ?? nameController.text,
        prefix: _state.selectedStyle!.prefix,
        suffix: _state.selectedStyle!.suffix,
        negativeContent: finalContent,
        isDefault: isDefault ?? _state.selectedStyle!.isDefault,
      );
    } else {
      final currentIsPrefix = isPrefix ?? _state.selectedStyle!.prefix.isNotEmpty || _state.selectedStyle!.suffix.isEmpty;
      updated = PromptStyle(
        name: name ?? nameController.text,
        prefix: currentIsPrefix ? finalContent : "",
        suffix: currentIsPrefix ? "" : finalContent,
        negativeContent: _state.selectedStyle!.negativeContent,
        isDefault: isDefault ?? _state.selectedStyle!.isDefault,
      );
    }

    _state = _state.copyWith(
      selectedStyle: updated,
      isModified: true,
    );
    notifyListeners();
  }

  Future<void> saveStyle() async {
    if (_state.selectedStyle == null) return;

    final index = _state.styles.indexWhere((s) => s.name == nameController.text);
    List<PromptStyle> updatedStyles;
    
    final finalStyle = _state.selectedStyle!;

    if (index != -1 && _state.styles[index].name == nameController.text) {
      updatedStyles = List<PromptStyle>.from(_state.styles)..[index] = finalStyle;
    } else {
      updatedStyles = List<PromptStyle>.from(_state.styles)..add(finalStyle);
    }

    _state = _state.copyWith(styles: updatedStyles, isModified: false);
    await StyleStorage.saveStyles(_stylesFilePath, updatedStyles);
    onStylesChanged();
    notifyListeners();
  }

  Future<void> deleteStyle(PromptStyle style) async {
    final updatedStyles = List<PromptStyle>.from(_state.styles)..removeWhere((s) => s.name == style.name);
    if (_state.selectedStyle?.name == style.name) {
      selectStyle(null);
    }
    _state = _state.copyWith(styles: updatedStyles);
    await StyleStorage.saveStyles(_stylesFilePath, updatedStyles);
    onStylesChanged();
    notifyListeners();
  }

  void duplicateStyle(PromptStyle style) {
    final newStyle = PromptStyle(
      name: "${style.name} (Copy)",
      prefix: style.prefix,
      suffix: style.suffix,
      negativeContent: style.negativeContent,
      isDefault: style.isDefault,
    );

    final updatedStyles = List<PromptStyle>.from(_state.styles)..add(newStyle);
    _state = _state.copyWith(styles: updatedStyles);
    StyleStorage.saveStyles(_stylesFilePath, updatedStyles).then((_) => onStylesChanged());
    notifyListeners();
  }

  Future<void> reorderStyles(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final updatedStyles = List<PromptStyle>.from(_state.styles);
    final item = updatedStyles.removeAt(oldIndex);
    updatedStyles.insert(newIndex, item);
    _state = _state.copyWith(styles: updatedStyles);
    await StyleStorage.saveStyles(_stylesFilePath, updatedStyles);
    onStylesChanged();
    notifyListeners();
  }

  bool hasNameConflict() {
    final currentName = nameController.text.trim();
    if (currentName.isEmpty) return false;
    return _state.styles.any((s) => s.name == currentName && s.name != _state.originalName);
  }

  void createNewStyle() {
    final newStyle = PromptStyle(
      name: "NEW STYLE",
      prefix: "",
      suffix: "",
      negativeContent: "",
      isDefault: false,
    );
    selectStyle(newStyle);
  }

  void handleTagSuggestions(String text, TextSelection selection) {
    final result = TagSuggestionHelper.getSuggestions(
      text: text,
      selection: selection,
      tagService: _tagService,
      supportFavorites: true,
      wildcardService: _wildcardService,
    );
    _state = _state.copyWith(
      tagSuggestions: result.suggestions,
      currentTagQuery: result.query,
    );
    notifyListeners();
  }

  void clearTagSuggestions() {
    if (_state.tagSuggestions.isEmpty) return;
    _state = _state.copyWith(tagSuggestions: [], currentTagQuery: "");
    notifyListeners();
  }

  void applyTagSuggestion(DanbooruTag tag) {
    TagSuggestionHelper.applyTag(contentController, tag);
    _state = _state.copyWith(tagSuggestions: [], currentTagQuery: "");
    updateCurrentStyle(content: contentController.text);
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    contentController.dispose();
    super.dispose();
  }
}
