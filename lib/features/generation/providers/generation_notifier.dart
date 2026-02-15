import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../../../core/services/preferences_service.dart';
import '../../../novel_ai_service.dart';
import '../../../wildcard_processor.dart';
import '../../../presets.dart';
import '../../../tag_service.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/services/wildcard_service.dart';
import '../../../core/utils/tag_suggestion_helper.dart';
import '../../../styles.dart';
import '../../gallery/providers/gallery_notifier.dart';
import '../../tools/providers/tag_library_notifier.dart';
import '../models/nai_character.dart';
import '../../tools/cascade/services/cascade_stitching_service.dart';
import '../../tools/img2img/services/img2img_request_builder.dart';
import '../../director_ref/models/director_reference.dart';
import '../../director_ref/providers/director_ref_notifier.dart';
import '../../vibe_transfer/models/vibe_transfer.dart';
import '../../vibe_transfer/providers/vibe_transfer_notifier.dart';
import 'package:dio/dio.dart';

class GenerationState {
  final Uint8List? generatedImage;
  final bool isLoading;
  final bool isDragging;
  final bool isSettingsExpanded;
  final List<GenerationPreset> presets;
  final List<PromptStyle> styles;
  final List<DanbooruTag> tagSuggestions;
  final String currentTagQuery;

  // Generation Settings
  final double width;
  final double height;
  final double scale;
  final double steps;
  final String sampler;
  final bool smea;
  final bool smeaDyn;
  final bool decrisper;
  final bool randomizeSeed;
  final List<String> activeStyleNames;
  final bool isStyleEnabled;
  final String apiKey;
  final bool autoSaveImages;
  final bool hasAuthError;
  final List<NaiCharacter> characters;
  final List<NaiInteraction> interactions;
  final bool showDirectorRefShelf;
  final bool showVibeTransferShelf;
  final bool brightTheme;
  final bool autoPositioning;
  final bool showEditButton;
  final String? errorMessage;

  GenerationState({
    this.generatedImage,
    this.isLoading = false,
    this.isDragging = false,
    this.isSettingsExpanded = false,
    this.presets = const [],
    this.styles = const [],
    this.tagSuggestions = const [],
    this.currentTagQuery = "",
    this.width = 832,
    this.height = 1216,
    this.scale = 5.0,
    this.steps = 28,
    this.sampler = "k_euler_ancestral",
    this.smea = false,
    this.smeaDyn = false,
    this.decrisper = false,
    this.randomizeSeed = true,
    this.activeStyleNames = const [],
    this.isStyleEnabled = true,
    this.apiKey = '',
    this.autoSaveImages = true,
    this.hasAuthError = false,
    this.characters = const [],
    this.interactions = const [],
    this.showDirectorRefShelf = true,
    this.showVibeTransferShelf = true,
    this.brightTheme = true,
    this.autoPositioning = false,
    this.showEditButton = true,
    this.errorMessage,
  });

  GenerationState copyWith({
    Uint8List? generatedImage,
    bool? isLoading,
    bool? isDragging,
    bool? isSettingsExpanded,
    List<GenerationPreset>? presets,
    List<PromptStyle>? styles,
    List<DanbooruTag>? tagSuggestions,
    String? currentTagQuery,
    double? width,
    double? height,
    double? scale,
    double? steps,
    String? sampler,
    bool? smea,
    bool? smeaDyn,
    bool? decrisper,
    bool? randomizeSeed,
    List<String>? activeStyleNames,
    bool? isStyleEnabled,
    String? apiKey,
    bool? autoSaveImages,
    bool? hasAuthError,
    List<NaiCharacter>? characters,
    List<NaiInteraction>? interactions,
    bool? showDirectorRefShelf,
    bool? showVibeTransferShelf,
    bool? brightTheme,
    bool? autoPositioning,
    bool? showEditButton,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return GenerationState(
      generatedImage: generatedImage ?? this.generatedImage,
      isLoading: isLoading ?? this.isLoading,
      isDragging: isDragging ?? this.isDragging,
      isSettingsExpanded: isSettingsExpanded ?? this.isSettingsExpanded,
      presets: presets ?? this.presets,
      styles: styles ?? this.styles,
      tagSuggestions: tagSuggestions ?? this.tagSuggestions,
      currentTagQuery: currentTagQuery ?? this.currentTagQuery,
      width: width ?? this.width,
      height: height ?? this.height,
      scale: scale ?? this.scale,
      steps: steps ?? this.steps,
      sampler: sampler ?? this.sampler,
      smea: smea ?? this.smea,
      smeaDyn: smeaDyn ?? this.smeaDyn,
      decrisper: decrisper ?? this.decrisper,
      randomizeSeed: randomizeSeed ?? this.randomizeSeed,
      activeStyleNames: activeStyleNames ?? this.activeStyleNames,
      isStyleEnabled: isStyleEnabled ?? this.isStyleEnabled,
      apiKey: apiKey ?? this.apiKey,
      autoSaveImages: autoSaveImages ?? this.autoSaveImages,
      hasAuthError: hasAuthError ?? this.hasAuthError,
      characters: characters ?? this.characters,
      interactions: interactions ?? this.interactions,
      showDirectorRefShelf: showDirectorRefShelf ?? this.showDirectorRefShelf,
      showVibeTransferShelf: showVibeTransferShelf ?? this.showVibeTransferShelf,
      brightTheme: brightTheme ?? this.brightTheme,
      autoPositioning: autoPositioning ?? this.autoPositioning,
      showEditButton: showEditButton ?? this.showEditButton,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class GenerationNotifier extends ChangeNotifier {
  GenerationState _state = GenerationState();
  GenerationState get state => _state;

  late NovelAIService _service;
  late final WildcardProcessor _wildcardProcessor;
  late final TagService _tagService;
  late final WildcardService _wildcardService;
  final PreferencesService _prefs;
  final String _outputDir;
  final String _presetsFilePath;
  final String _stylesFilePath;
  GalleryNotifier? _galleryNotifier;
  DirectorRefNotifier? _directorRefNotifier;
  VibeTransferNotifier? _vibeTransferNotifier;

  TagService get tagService => _tagService;
  WildcardService get wildcardService => _wildcardService;
  String get presetsFilePath => _presetsFilePath;
  String get stylesFilePath => _stylesFilePath;

  Map<String, dynamic>? _lastMetadata;
  bool _imageSaved = false;
  bool get imageSaved => _imageSaved;

  Timer? _tagDebounce;
  late final String _sessionFilePath;
  Timer? _sessionSaveDebounce;
  bool _sessionReady = false;
  final TextEditingController promptController = TextEditingController();
  final TextEditingController negativePromptController = TextEditingController(
    text: ""
  );

  static const String defaultNegativePrompt = "lowres, {bad}, error, fewer, extra, missing, worst quality, jpeg artifacts, bad quality, watermark, unfinished, displeasing, chromatic aberration, signature, extra digits, artistic error, username, scan, [abstract]";
  final TextEditingController seedController = TextEditingController();

  GenerationNotifier({
    required PreferencesService preferences,
    required String wildcardDir,
    required String tagFilePath,
    required String outputDir,
    required String presetsFilePath,
    required String stylesFilePath,
    GalleryNotifier? galleryNotifier,
  }) : _prefs = preferences,
       _outputDir = outputDir,
       _presetsFilePath = presetsFilePath,
       _stylesFilePath = stylesFilePath,
       _galleryNotifier = galleryNotifier {
    _service = NovelAIService(''); // initialized with empty key, loaded async
    _wildcardProcessor = WildcardProcessor(wildcardDir: wildcardDir);
    _tagService = TagService(filePath: tagFilePath);
    _wildcardService = WildcardService(wildcardDir: wildcardDir);
    _sessionFilePath = p.join(p.dirname(presetsFilePath), 'session_snapshot.json');

    negativePromptController.text = "";
    _loadInitialData();
  }

  void updateGalleryNotifier(GalleryNotifier galleryNotifier) {
    _galleryNotifier = galleryNotifier;
  }

  void updateDirectorRefNotifier(DirectorRefNotifier notifier) {
    _directorRefNotifier = notifier;
  }

  void updateVibeTransferNotifier(VibeTransferNotifier notifier) {
    _vibeTransferNotifier = notifier;
    notifier.updateService(_service);
  }

  Future<void> _loadInitialData() async {
    await _tagService.loadTags();
    await _wildcardService.refresh();
    final presets = await PresetStorage.loadPresets(_presetsFilePath);
    final styles = await StyleStorage.loadStyles(_stylesFilePath);

    // Default style selection: Light - NAI, or those marked as default, or first available
    List<String> initialActiveStyles = [];
    if (styles.any((s) => s.name == "Light - NAI")) {
      initialActiveStyles = ["Light - NAI"];
    } else {
      final defaultStyleNames = styles.where((s) => s.isDefault).map((s) => s.name).toList();
      initialActiveStyles = defaultStyleNames.isNotEmpty
          ? defaultStyleNames
          : (styles.isNotEmpty ? [styles.first.name] : <String>[]);
    }

    final apiKey = await _prefs.getApiKey();
    _service = NovelAIService(apiKey);
    _vibeTransferNotifier?.updateService(_service);

    _state = _state.copyWith(
      presets: presets,
      styles: styles,
      activeStyleNames: initialActiveStyles,
      apiKey: apiKey,
      autoSaveImages: _prefs.autoSaveImages,
      showDirectorRefShelf: _prefs.showDirectorRefShelf,
      showVibeTransferShelf: _prefs.showVibeTransferShelf,
      brightTheme: _prefs.brightTheme,
      showEditButton: _prefs.showEditButton,
    );
    notifyListeners();

    await _restoreSessionSnapshot();
    _sessionReady = true;
  }

  Future<void> reloadPresetsAndStyles() async {
    final presets = await PresetStorage.loadPresets(_presetsFilePath);
    final styles = await StyleStorage.loadStyles(_stylesFilePath);
    _state = _state.copyWith(presets: presets, styles: styles);
    notifyListeners();
  }

  Future<void> updateApiKey(String key) async {
    await _prefs.setApiKey(key);
    _service = NovelAIService(key);
    _vibeTransferNotifier?.updateService(_service);
    _state = _state.copyWith(apiKey: key, hasAuthError: false);
    notifyListeners();
  }

  Future<void> toggleAutoSave(bool value) async {
    await _prefs.setAutoSaveImages(value);
    _state = _state.copyWith(autoSaveImages: value);
    notifyListeners();
  }

  Future<void> toggleBrightTheme() async {
    final newVal = !_state.brightTheme;
    await _prefs.setBrightTheme(newVal);
    _state = _state.copyWith(brightTheme: newVal);
    notifyListeners();
  }

  Future<void> toggleDirectorRefShelf() async {
    final newVal = !_state.showDirectorRefShelf;
    await _prefs.setShowDirectorRefShelf(newVal);
    _state = _state.copyWith(showDirectorRefShelf: newVal);
    notifyListeners();
  }

  Future<void> toggleVibeTransferShelf() async {
    final newVal = !_state.showVibeTransferShelf;
    await _prefs.setShowVibeTransferShelf(newVal);
    _state = _state.copyWith(showVibeTransferShelf: newVal);
    notifyListeners();
  }

  Future<void> toggleShowEditButton() async {
    final newVal = !_state.showEditButton;
    await _prefs.setShowEditButton(newVal);
    _state = _state.copyWith(showEditButton: newVal);
    notifyListeners();
  }

  void setAutoPositioning(bool value) {
    _state = _state.copyWith(autoPositioning: value);
    notifyListeners();
  }

  void clearError() {
    _state = _state.copyWith(clearErrorMessage: true);
    notifyListeners();
  }

  void clearAuthError() {
    _state = _state.copyWith(hasAuthError: false);
    notifyListeners();
  }

  void toggleSettings() {
    _state = _state.copyWith(isSettingsExpanded: !_state.isSettingsExpanded);
    notifyListeners();
  }

  void setDragging(bool dragging) {
    _state = _state.copyWith(isDragging: dragging);
    notifyListeners();
  }

  void updateSettings({
    double? width,
    double? height,
    double? steps,
    double? scale,
    String? sampler,
    bool? smea,
    bool? smeaDyn,
    bool? decrisper,
    bool? randomizeSeed,
    List<String>? activeStyleNames,
    bool? isStyleEnabled,
    List<NaiCharacter>? characters,
  }) {
    _state = _state.copyWith(
      width: width,
      height: height,
      steps: steps,
      scale: scale,
      sampler: sampler,
      smea: smea,
      smeaDyn: smeaDyn,
      decrisper: decrisper,
      randomizeSeed: randomizeSeed,
      activeStyleNames: activeStyleNames,
      isStyleEnabled: isStyleEnabled,
      characters: characters,
    );
    notifyListeners();
  }

  void addCharacter() {
    if (_state.characters.length >= 6) return;
    final updated = List<NaiCharacter>.from(_state.characters)
      ..add(NaiCharacter(
        prompt: "",
        uc: "",
        center: NaiCoordinate(x: 0.5, y: 0.5),
      ));
    _state = _state.copyWith(characters: updated);
    notifyListeners();
  }

  void updateCharacter(int index, NaiCharacter character) {
    if (index < 0 || index >= _state.characters.length) return;
    final updated = List<NaiCharacter>.from(_state.characters);
    updated[index] = character;
    _state = _state.copyWith(characters: updated);
    notifyListeners();
  }

  void removeCharacter(int index) {
    if (index < 0 || index >= _state.characters.length) return;
    
    // Update characters
    final updatedChars = List<NaiCharacter>.from(_state.characters)..removeAt(index);
    
    // Cleanup interactions involving this character or with higher indices
    final updatedInteractions = _state.interactions
        .where((i) => i.sourceCharacterIndex != index && i.targetCharacterIndex != index)
        .map((i) {
          int newSource = i.sourceCharacterIndex;
          int newTarget = i.targetCharacterIndex;
          if (newSource > index) newSource--;
          if (newTarget > index) newTarget--;
          return i.copyWith(
            sourceCharacterIndex: newSource,
            targetCharacterIndex: newTarget,
          );
        })
        .toList();

    _state = _state.copyWith(
      characters: updatedChars,
      interactions: updatedInteractions,
    );
    notifyListeners();
  }

  void updateInteraction(NaiInteraction interaction) {
    final updated = List<NaiInteraction>.from(_state.interactions);
    final existingIndex = updated.indexWhere((i) =>
        (i.sourceCharacterIndex == interaction.sourceCharacterIndex &&
            i.targetCharacterIndex == interaction.targetCharacterIndex) ||
        (i.sourceCharacterIndex == interaction.targetCharacterIndex &&
            i.targetCharacterIndex == interaction.sourceCharacterIndex));

    if (existingIndex >= 0) {
      if (interaction.actionName.isEmpty) {
        updated.removeAt(existingIndex);
      } else {
        updated[existingIndex] = interaction;
      }
    } else if (interaction.actionName.isNotEmpty) {
      updated.add(interaction);
    }

    _state = _state.copyWith(interactions: updated);
    notifyListeners();
  }

  void setGeneratedImage(Uint8List? image) {
    _state = _state.copyWith(generatedImage: image);
    notifyListeners();
  }

  Future<void> saveCurrentImage() async {
    if (_state.generatedImage == null || _lastMetadata == null) return;
    final savedFile = await _saveToDisk(_state.generatedImage!, _lastMetadata!);
    if (savedFile != null) {
      _galleryNotifier?.addFile(savedFile, DateTime.now());
      _imageSaved = true;
      notifyListeners();
    }
  }

  void removeInteraction(int index1, int index2) {
    final updated = List<NaiInteraction>.from(_state.interactions);
    updated.removeWhere((i) =>
        (i.sourceCharacterIndex == index1 && i.targetCharacterIndex == index2) ||
        (i.sourceCharacterIndex == index2 && i.targetCharacterIndex == index1));
    _state = _state.copyWith(interactions: updated);
    notifyListeners();
  }

  void toggleStyle(String name) {
    final current = List<String>.from(_state.activeStyleNames);
    if (current.contains(name)) {
      current.remove(name);
    } else {
      current.add(name);
    }
    _state = _state.copyWith(activeStyleNames: current);
    notifyListeners();
  }

  Future<void> generate() async {
    clearTagSuggestions();

    _state = _state.copyWith(isLoading: true, hasAuthError: false);
    notifyListeners();

    try {
      final processedPrompt = await _wildcardProcessor.process(promptController.text);

      String finalPrompt = processedPrompt;
      if (_galleryNotifier?.demoMode == true) {
        final demoPos = _prefs.demoPositivePrefix;
        if (demoPos.isNotEmpty) {
          finalPrompt = '$demoPos, $finalPrompt';
        }
      }

      int seed;
      if (_state.randomizeSeed) {
        seed = math.Random().nextInt(4294967295);
        seedController.text = seed.toString();
      } else {
        seed = int.tryParse(seedController.text) ?? 0;
      }

      String? combinedPrefix;
      String? combinedSuffix;
      String? styleNegativeContent;

      if (_state.isStyleEnabled && _state.activeStyleNames.isNotEmpty) {
        final List<String> prefixes = [];
        final List<String> suffixes = [];
        final List<String> negatives = [];

        for (final styleName in _state.activeStyleNames) {
          try {
            final style = _state.styles.firstWhere((s) => s.name == styleName);
            if (style.prefix.isNotEmpty) prefixes.add(style.prefix);
            if (style.suffix.isNotEmpty) suffixes.add(style.suffix);
            if (style.negativeContent.isNotEmpty) negatives.add(style.negativeContent);
          } catch (_) {}
        }

        if (prefixes.isNotEmpty) combinedPrefix = prefixes.join("");
        if (suffixes.isNotEmpty) combinedSuffix = suffixes.join("");
        if (negatives.isNotEmpty) styleNegativeContent = negatives.join("");
      }

      String baseNegative = negativePromptController.text;
      if (_galleryNotifier?.demoMode == true) {
        final demoNeg = _prefs.demoNegativePrefix;
        if (demoNeg.isNotEmpty) {
          baseNegative = baseNegative.isEmpty ? demoNeg : '$demoNeg, $baseNegative';
        }
      }
      final fullNegativePrompt = styleNegativeContent != null ? "$baseNegative, $styleNegativeContent" : baseNegative;

      final dirPayload = _directorRefNotifier?.buildPayload();
      final vibePayload = _vibeTransferNotifier?.buildPayload();

      final result = await _service.generateImage(
        prompt: finalPrompt,
        negativePrompt: fullNegativePrompt,
        width: _state.width.toInt(),
        height: _state.height.toInt(),
        scale: _state.scale,
        steps: _state.steps.toInt(),
        sampler: _state.sampler,
        smea: _state.smea,
        smeaDyn: _state.smeaDyn,
        decrisper: _state.decrisper,
        seed: seed,
        promptPrefix: combinedPrefix,
        promptSuffix: combinedSuffix,
        characters: _state.characters,
        interactions: _state.interactions,
        useCoords: _state.characters.isNotEmpty ? !_state.autoPositioning : false,
        directorRefImages: dirPayload?.images,
        directorRefDescriptions: dirPayload?.descriptions,
        directorRefStrengths: dirPayload?.strengths,
        directorRefSecondaryStrengths: dirPayload?.secondaryStrengths,
        directorRefInfoExtracted: dirPayload?.infoExtracted,
        vibeTransferImages: vibePayload?.vibeVectors,
        vibeTransferStrengths: vibePayload?.strengths,
        vibeTransferInfoExtracted: vibePayload?.infoExtracted,
      );

      // Save active style info in metadata for round-trip restore
      result.metadata['active_style_names'] =
          (_state.isStyleEnabled && _state.activeStyleNames.isNotEmpty)
              ? _state.activeStyleNames
              : <String>[];
      result.metadata['is_style_enabled'] = _state.isStyleEnabled;
      result.metadata['original_negative_prompt'] = baseNegative;

      _lastMetadata = result.metadata;
      _imageSaved = false;
      _state = _state.copyWith(generatedImage: result.imageBytes);
      if (_state.autoSaveImages) {
        final savedFile = await _saveToDisk(result.imageBytes, result.metadata);
        if (savedFile != null) {
          _galleryNotifier?.addFile(savedFile, DateTime.now());
          _imageSaved = true;
        }
      }
    } on UnauthorizedException {
      _state = _state.copyWith(hasAuthError: true);
    } catch (e) {
      debugPrint("Generation error: $e");
      _state = _state.copyWith(errorMessage: _formatError(e));
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<File?> _saveToDisk(Uint8List bytes, Map<String, dynamic> metadata) async {
    try {
      final directory = Directory(_outputDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmssSSS').format(DateTime.now());
      final filePath = p.join(directory.path, 'Gen_$timestamp.png');

      final bytesWithMetadata = await compute(injectMetadata, {
        'bytes': bytes,
        'metadata': metadata,
      });
      
      final file = File(filePath);
      await file.writeAsBytes(bytesWithMetadata);
      return file;
    } catch (e) {
      debugPrint("Save error: $e");
      return null;
    }
  }

  void handleTagSuggestions(String text, TextSelection selection) {
    if (_galleryNotifier?.demoMode == true) {
      clearTagSuggestions();
      return;
    }
    _tagDebounce?.cancel();
    _tagDebounce = Timer(const Duration(milliseconds: 150), () {
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
    });
  }

  void clearTagSuggestions() {
    if (_state.tagSuggestions.isEmpty) return;
    _state = _state.copyWith(tagSuggestions: [], currentTagQuery: "");
    notifyListeners();
  }

  void applyTagSuggestion(DanbooruTag tag) {
    TagSuggestionHelper.applyTag(promptController, tag);
    _state = _state.copyWith(tagSuggestions: [], currentTagQuery: "");
    notifyListeners();
  }

  Future<void> importImageMetadata(File file) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final bytes = await file.readAsBytes();
      final metadata = await compute(extractMetadata, bytes);

      if (metadata == null || metadata.isEmpty) throw Exception("No metadata found");

      String? prompt;
      String? negativePrompt;
      Map<String, dynamic>? settings;

      // NovelAI stores generation parameters in the 'Comment' field as JSON
      final smartImport = _prefs.smartStyleImport;

      if (metadata.containsKey('Comment')) {
        settings = parseCommentJson(metadata['Comment']!);

        if (settings != null) {
          // Check if style metadata was saved with this image
          final savedStyleNames = settings['active_style_names'];

          if (smartImport && savedStyleNames is List && savedStyleNames.isNotEmpty) {
            // Smart import: use original prompt (without style prefix/suffix)
            prompt = settings['original_prompt'] ?? settings['prompt'];
            negativePrompt = settings['original_negative_prompt'] ?? settings['uc'];
          } else {
            // Raw import or legacy: use composed prompt as-is
            prompt = settings['prompt'];
            prompt ??= settings['original_prompt'];
            negativePrompt = settings['uc'];
          }

          negativePrompt ??= settings['undesired_content'];

          // Deep extraction for V4.5 structure if direct keys are missing
          if (negativePrompt == null || negativePrompt.isEmpty) {
            negativePrompt = settings['v4_negative_prompt']?['caption']?['base_caption'];
          }
        }
      }
      
      // If prompt is still missing, try Description (standard PNG chunk)
      prompt ??= metadata['Description'];

      if (prompt != null) {
        promptController.value = TextEditingValue(
          text: prompt,
          selection: TextSelection.collapsed(offset: prompt.length),
        );

        if (negativePrompt != null) {
          negativePromptController.value = TextEditingValue(
            text: negativePrompt,
            selection: TextSelection.collapsed(offset: negativePrompt.length),
          );
        }

        if (settings != null) {
          _state = _state.copyWith(
            width: (settings['width'] as num?)?.toDouble(),
            height: (settings['height'] as num?)?.toDouble(),
            scale: (settings['scale'] as num?)?.toDouble(),
            steps: (settings['steps'] as num?)?.toDouble(),
            sampler: settings['sampler']?.toString(),
            smea: settings['sm'] as bool?,
            smeaDyn: settings['sm_dyn'] as bool?,
            decrisper: settings['dynamic_thresholding'] as bool?,
            randomizeSeed: false,
            generatedImage: bytes,
          );
          if (settings['seed'] != null) seedController.text = settings['seed'].toString();

          // Restore active styles based on smart import toggle
          final savedStyleNames = settings['active_style_names'];
          final savedStyleEnabled = settings['is_style_enabled'];
          if (smartImport && savedStyleNames is List && savedStyleNames.isNotEmpty) {
            // Smart: restore style selections so re-generation applies them
            final styleNames = savedStyleNames.cast<String>().toList();
            _state = _state.copyWith(
              activeStyleNames: styleNames,
              isStyleEnabled: savedStyleEnabled == true,
            );
          } else {
            // Raw or legacy: styles are baked into the prompt, disable to avoid doubling
            _state = _state.copyWith(
              activeStyleNames: <String>[],
              isStyleEnabled: false,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Metadata extraction error: $e");
      rethrow;
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<void> savePreset(String name) async {
    final newPreset = GenerationPreset(
      name: name,
      prompt: promptController.text,
      negativePrompt: negativePromptController.text,
      width: _state.width,
      height: _state.height,
      scale: _state.scale,
      steps: _state.steps,
      sampler: _state.sampler,
      smea: _state.smea,
      smeaDyn: _state.smeaDyn,
      decrisper: _state.decrisper,
      characters: List<NaiCharacter>.from(_state.characters),
      interactions: List<NaiInteraction>.from(_state.interactions),
      directorReferences: _directorRefNotifier?.references.toList() ?? const [],
      vibeTransfers: _vibeTransferNotifier?.vibes.toList() ?? const [],
    );

    final updatedPresets = List<GenerationPreset>.from(_state.presets)..add(newPreset);
    _state = _state.copyWith(presets: updatedPresets);
    notifyListeners();
    await PresetStorage.savePresets(_presetsFilePath, updatedPresets);
  }

  void applyPreset(GenerationPreset preset) {
    promptController.text = preset.prompt;
    negativePromptController.text = preset.negativePrompt;
    _state = _state.copyWith(
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
    );
    if (preset.directorReferences.isNotEmpty) {
      _directorRefNotifier?.setReferences(preset.directorReferences);
    } else {
      _directorRefNotifier?.clearAll();
    }
    if (preset.vibeTransfers.isNotEmpty) {
      _vibeTransferNotifier?.setVibes(preset.vibeTransfers);
    } else {
      _vibeTransferNotifier?.clearAll();
    }
    notifyListeners();
  }

  Future<void> refreshPresets() async {
    final presets = await PresetStorage.loadPresets(_presetsFilePath);
    _state = _state.copyWith(presets: presets);
    notifyListeners();
  }

  Future<void> refreshStyles() async {
    final styles = await StyleStorage.loadStyles(_stylesFilePath);
    _state = _state.copyWith(styles: styles);
    notifyListeners();
  }

  Future<void> deletePreset(int index) async {
    final updatedPresets =
        List<GenerationPreset>.from(_state.presets)..removeAt(index);
    _state = _state.copyWith(presets: updatedPresets);
    notifyListeners();
    await PresetStorage.savePresets(_presetsFilePath, updatedPresets);
  }

  Future<Uint8List?> generateQuickPreview(String tag,
      {TagPreviewSettings? previewSettings}) async {
    final settings = previewSettings ?? TagPreviewSettings();

    try {
      final seed = settings.seed ?? math.Random().nextInt(4294967295);
      final result = await _service.generateImage(
        prompt: "${settings.positivePrompt}, $tag",
        negativePrompt: settings.negativePrompt,
        width: settings.width.toInt(),
        height: settings.height.toInt(),
        scale: settings.scale,
        steps: settings.steps,
        sampler: settings.sampler,
        seed: seed,
      );

      // Auto-save the preview as well, so it's in the gallery
      if (_state.autoSaveImages) {
        final savedFile = await _saveToDisk(result.imageBytes, result.metadata);
        if (savedFile != null) {
          _galleryNotifier?.addFile(savedFile, DateTime.now());
        }
      }

      return result.imageBytes;
    } catch (e) {
      debugPrint("Quick preview error: $e");
      return null;
    }
  }

  Future<Uint8List?> generateCascadeBeat(CascadeStitchedRequest request) async {
    _state = _state.copyWith(isLoading: true, hasAuthError: false);
    notifyListeners();

    try {
      final seed = math.Random().nextInt(4294967295);
      
      final combinedNegative = [defaultNegativePrompt, request.negativePrompt]
          .where((s) => s.isNotEmpty).join(', ');

      final result = await _service.generateImage(
        prompt: request.baseCaption,
        negativePrompt: combinedNegative,
        width: request.width,
        height: request.height,
        scale: request.scale,
        steps: request.steps,
        sampler: request.sampler,
        seed: seed,
        characters: request.characters,
        useCoords: request.useCoords,
      );

      _lastMetadata = result.metadata;
      _imageSaved = false;
      _state = _state.copyWith(generatedImage: result.imageBytes);

      if (_state.autoSaveImages) {
        final savedFile = await _saveToDisk(result.imageBytes, result.metadata);
        if (savedFile != null) {
          _galleryNotifier?.addFile(savedFile, DateTime.now());
          _imageSaved = true;
        }
      }

      return result.imageBytes;
    } on UnauthorizedException {
      _state = _state.copyWith(hasAuthError: true);
      return null;
    } catch (e) {
      debugPrint("Cascade generation error: $e");
      _state = _state.copyWith(errorMessage: _formatError(e));
      return null;
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  Future<Uint8List?> generateImg2Img(Img2ImgRequest request) async {
    _state = _state.copyWith(isLoading: true, hasAuthError: false);
    notifyListeners();

    try {
      final seed = _state.randomizeSeed
          ? math.Random().nextInt(4294967295)
          : (int.tryParse(seedController.text) ?? math.Random().nextInt(4294967295));
      if (_state.randomizeSeed) seedController.text = seed.toString();

      final result = await _service.generateImage(
        prompt: request.prompt,
        negativePrompt: request.negativePrompt,
        width: request.width,
        height: request.height,
        scale: request.scale,
        steps: request.steps,
        sampler: request.sampler,
        seed: seed,
        action: request.maskBase64 != null ? 'infill' : 'img2img',
        sourceImageBase64: request.sourceImageBase64,
        maskBase64: request.maskBase64,
        img2imgStrength: request.strength,
        img2imgNoise: request.noise,
        img2imgColorCorrect: request.colorCorrect,
        maskBlur: request.maskBase64 != null ? request.maskBlur : null,
      );

      Uint8List finalBytes = result.imageBytes;

      _lastMetadata = result.metadata;
      _imageSaved = false;
      _state = _state.copyWith(generatedImage: finalBytes);

      if (_state.autoSaveImages) {
        final savedFile = await _saveToDisk(finalBytes, result.metadata);
        if (savedFile != null) {
          _galleryNotifier?.addFile(savedFile, DateTime.now());
          _imageSaved = true;
        }
      }

      return finalBytes;
    } on UnauthorizedException {
      _state = _state.copyWith(hasAuthError: true);
      return null;
    } catch (e) {
      debugPrint("Img2Img generation error: $e");
      _state = _state.copyWith(errorMessage: _formatError(e));
      return null;
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  String _formatError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status != null) return 'API ERROR $status';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'CONNECTION TIMEOUT';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'CONNECTION ERROR';
      }
      return 'NETWORK ERROR';
    }
    return 'GENERATION FAILED';
  }

  // — Session snapshot (remember session) —

  @override
  void notifyListeners() {
    super.notifyListeners();
    _scheduleSessionSave();
  }

  void _scheduleSessionSave() {
    if (!_sessionReady || !_prefs.rememberSession) return;
    _sessionSaveDebounce?.cancel();
    _sessionSaveDebounce = Timer(const Duration(seconds: 5), () {
      _saveSessionSnapshot();
    });
  }

  Future<void> _saveSessionSnapshot() async {
    try {
      final snapshot = <String, dynamic>{
        'prompt': promptController.text,
        'negative_prompt': negativePromptController.text,
        'seed': seedController.text,
        'width': _state.width,
        'height': _state.height,
        'scale': _state.scale,
        'steps': _state.steps,
        'sampler': _state.sampler,
        'smea': _state.smea,
        'smea_dyn': _state.smeaDyn,
        'decrisper': _state.decrisper,
        'randomize_seed': _state.randomizeSeed,
        'auto_positioning': _state.autoPositioning,
        'active_style_names': _state.activeStyleNames,
        'is_style_enabled': _state.isStyleEnabled,
        'characters': _state.characters.map((c) => c.toJson()).toList(),
        'interactions': _state.interactions.map((i) => i.toJson()).toList(),
        'director_references': _directorRefNotifier?.references
            .map((r) => r.toJson()).toList() ?? [],
        'vibe_transfers': _vibeTransferNotifier?.vibes
            .map((v) => v.toJson()).toList() ?? [],
      };
      await File(_sessionFilePath).writeAsString(jsonEncode(snapshot));
    } catch (e) {
      debugPrint('Session save error: $e');
    }
  }

  Future<void> _restoreSessionSnapshot() async {
    if (!_prefs.rememberSession) return;
    try {
      final file = File(_sessionFilePath);
      if (!await file.exists()) return;

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      promptController.text = json['prompt'] as String? ?? '';
      negativePromptController.text = json['negative_prompt'] as String? ?? '';
      seedController.text = json['seed'] as String? ?? '';

      final characters = (json['characters'] as List<dynamic>?)
          ?.map((c) => NaiCharacter.fromJson(c as Map<String, dynamic>))
          .toList() ?? [];
      final interactions = (json['interactions'] as List<dynamic>?)
          ?.map((i) => NaiInteraction.fromJson(i as Map<String, dynamic>))
          .toList() ?? [];

      _state = _state.copyWith(
        width: (json['width'] as num?)?.toDouble(),
        height: (json['height'] as num?)?.toDouble(),
        scale: (json['scale'] as num?)?.toDouble(),
        steps: (json['steps'] as num?)?.toDouble(),
        sampler: json['sampler'] as String?,
        smea: json['smea'] as bool?,
        smeaDyn: json['smea_dyn'] as bool?,
        decrisper: json['decrisper'] as bool?,
        randomizeSeed: json['randomize_seed'] as bool?,
        autoPositioning: json['auto_positioning'] as bool?,
        activeStyleNames: (json['active_style_names'] as List<dynamic>?)
            ?.cast<String>().toList(),
        isStyleEnabled: json['is_style_enabled'] as bool?,
        characters: characters,
        interactions: interactions,
      );

      // Restore director references
      final dirRefs = (json['director_references'] as List<dynamic>?)
          ?.map((r) => DirectorReference.fromJson(r as Map<String, dynamic>))
          .toList();
      if (dirRefs != null && dirRefs.isNotEmpty) {
        _directorRefNotifier?.setReferences(dirRefs);
      }

      // Restore vibe transfers
      final vibeTransfers = (json['vibe_transfers'] as List<dynamic>?)
          ?.map((v) => VibeTransfer.fromJson(v as Map<String, dynamic>))
          .toList();
      if (vibeTransfers != null && vibeTransfers.isNotEmpty) {
        _vibeTransferNotifier?.setVibes(vibeTransfers);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Session restore error: $e');
    }
  }

  Future<void> deleteSessionSnapshot() async {
    try {
      final file = File(_sessionFilePath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Session delete error: $e');
    }
  }

  @override
  void dispose() {
    _tagDebounce?.cancel();
    _sessionSaveDebounce?.cancel();
    promptController.dispose();
    negativePromptController.dispose();
    seedController.dispose();
    super.dispose();
  }
}

