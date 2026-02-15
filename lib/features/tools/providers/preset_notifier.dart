import 'package:flutter/material.dart';
import '../../../core/services/wildcard_service.dart';
import '../../../core/utils/tag_suggestion_helper.dart';
import '../../../presets.dart';
import '../../../tag_service.dart';
import '../../director_ref/models/director_reference.dart';
import '../../generation/models/nai_character.dart';

class PresetState {
  final List<GenerationPreset> presets;
  final GenerationPreset? selectedPreset;
  final String? originalName;
  final List<DanbooruTag> tagSuggestions;
  final String currentTagQuery;
  final bool isModified;

  PresetState({
    this.presets = const [],
    this.selectedPreset,
    this.originalName,
    this.tagSuggestions = const [],
    this.currentTagQuery = "",
    this.isModified = false,
  });

  PresetState copyWith({
    List<GenerationPreset>? presets,
    GenerationPreset? selectedPreset,
    String? originalName,
    List<DanbooruTag>? tagSuggestions,
    String? currentTagQuery,
    bool? isModified,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      selectedPreset: selectedPreset ?? this.selectedPreset,
      originalName: originalName ?? this.originalName,
      tagSuggestions: tagSuggestions ?? this.tagSuggestions,
      currentTagQuery: currentTagQuery ?? this.currentTagQuery,
      isModified: isModified ?? this.isModified,
    );
  }
}

class PresetNotifier extends ChangeNotifier {
  PresetState _state = PresetState();
  PresetState get state => _state;

  final TagService _tagService;
  final WildcardService _wildcardService;
  final String _presetsFilePath;
  final VoidCallback onPresetsChanged;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController promptController = TextEditingController();
  final TextEditingController negativePromptController = TextEditingController();

  PresetNotifier({
    required TagService tagService,
    required WildcardService wildcardService,
    required List<GenerationPreset> initialPresets,
    required String presetsFilePath,
    required this.onPresetsChanged,
  }) : _tagService = tagService,
       _wildcardService = wildcardService,
       _presetsFilePath = presetsFilePath {
    _state = _state.copyWith(presets: initialPresets);
  }

  void selectPreset(GenerationPreset? preset) {
    _state = _state.copyWith(
      selectedPreset: preset,
      originalName: preset?.name,
      isModified: false,
      tagSuggestions: [],
    );

    if (preset != null) {
      nameController.text = preset.name;
      promptController.text = preset.prompt;
      negativePromptController.text = preset.negativePrompt;
    } else {
      nameController.clear();
      promptController.clear();
      negativePromptController.clear();
    }
    notifyListeners();
  }

  void updateCurrentPreset({
    String? name,
    String? prompt,
    String? negativePrompt,
    double? width,
    double? height,
    double? scale,
    double? steps,
    String? sampler,
    bool? smea,
    bool? smeaDyn,
    bool? decrisper,
    List<NaiCharacter>? characters,
    List<NaiInteraction>? interactions,
    List<DirectorReference>? directorReferences,
  }) {
    if (_state.selectedPreset == null) return;

    final updated = GenerationPreset(
      name: name ?? nameController.text,
      prompt: prompt ?? promptController.text,
      negativePrompt: negativePrompt ?? negativePromptController.text,
      width: width ?? _state.selectedPreset!.width,
      height: height ?? _state.selectedPreset!.height,
      scale: scale ?? _state.selectedPreset!.scale,
      steps: steps ?? _state.selectedPreset!.steps,
      sampler: sampler ?? _state.selectedPreset!.sampler,
      smea: smea ?? _state.selectedPreset!.smea,
      smeaDyn: smeaDyn ?? _state.selectedPreset!.smeaDyn,
      decrisper: decrisper ?? _state.selectedPreset!.decrisper,
      characters: characters ?? _state.selectedPreset!.characters,
      interactions: interactions ?? _state.selectedPreset!.interactions,
      directorReferences: directorReferences ?? _state.selectedPreset!.directorReferences,
    );

    _state = _state.copyWith(
      selectedPreset: updated,
      isModified: true,
    );
    notifyListeners();
  }

  Future<void> savePreset() async {
    if (_state.selectedPreset == null) return;

    final index = _state.presets.indexWhere((p) => p.name == nameController.text);
    List<GenerationPreset> updatedPresets;

    final finalPreset = _state.selectedPreset!;

    if (index != -1 && _state.presets[index].name == nameController.text) {
      // Update existing (if name matches)
      updatedPresets = List<GenerationPreset>.from(_state.presets)..[index] = finalPreset;
    } else {
      // Add new
      updatedPresets = List<GenerationPreset>.from(_state.presets)..add(finalPreset);
    }

    _state = _state.copyWith(presets: updatedPresets, isModified: false);
    await PresetStorage.savePresets(_presetsFilePath, updatedPresets);
    onPresetsChanged();
    notifyListeners();
  }

  Future<void> deletePreset(GenerationPreset preset) async {
    final updatedPresets = List<GenerationPreset>.from(_state.presets)..removeWhere((p) => p.name == preset.name);
    if (_state.selectedPreset?.name == preset.name) {
      selectPreset(null);
    }
    _state = _state.copyWith(presets: updatedPresets);
    await PresetStorage.savePresets(_presetsFilePath, updatedPresets);
    onPresetsChanged();
    notifyListeners();
  }

  void duplicatePreset(GenerationPreset preset) {
    final newPreset = GenerationPreset(
      name: "${preset.name} (Copy)",
      prompt: preset.prompt,
      negativePrompt: preset.negativePrompt,
      width: preset.width,
      height: preset.height,
      scale: preset.scale,
      steps: preset.steps,
      sampler: preset.sampler,
      smea: preset.smea,
      smeaDyn: preset.smeaDyn,
      decrisper: preset.decrisper,
      characters: List<NaiCharacter>.from(preset.characters),
      interactions: List<NaiInteraction>.from(preset.interactions),
      directorReferences: List<DirectorReference>.from(preset.directorReferences),
    );

    final updatedPresets = List<GenerationPreset>.from(_state.presets)..add(newPreset);
    _state = _state.copyWith(presets: updatedPresets);
    PresetStorage.savePresets(_presetsFilePath, updatedPresets).then((_) => onPresetsChanged());
    notifyListeners();
  }

  bool hasNameConflict() {
    final currentName = nameController.text.trim();
    if (currentName.isEmpty) return false;
    // Conflict if name exists and it's not the one we started editing
    return _state.presets.any((p) => p.name == currentName && p.name != _state.originalName);
  }

  void createNewPreset() {
    final newPreset = GenerationPreset(
      name: "NEW PRESET",
      prompt: "",
      negativePrompt: "",
      width: 832,
      height: 1216,
      scale: 6.0,
      steps: 28,
      sampler: "k_euler_ancestral",
      smea: false,
      smeaDyn: false,
      decrisper: false,
    );
    selectPreset(newPreset);
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
    TagSuggestionHelper.applyTag(promptController, tag);
    _state = _state.copyWith(tagSuggestions: [], currentTagQuery: "");
    updateCurrentPreset(prompt: promptController.text);
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    promptController.dispose();
    negativePromptController.dispose();
    super.dispose();
  }
}
