import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/novel_ai_service.dart';
import '../../../core/services/wildcard_processor.dart';
import '../../../core/services/presets.dart';
import '../../../core/services/tag_service.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/services/wildcard_service.dart';
import '../../../core/utils/tag_suggestion_helper.dart';
import '../../../core/services/styles.dart';
import '../../gallery/providers/gallery_notifier.dart';
import '../../tools/providers/tag_library_notifier.dart';
import '../models/nai_character.dart';
import '../models/character_preset.dart';
import '../../tools/cascade/services/cascade_stitching_service.dart';
import '../../tools/img2img/services/img2img_request_builder.dart';
import '../../director_ref/providers/director_ref_notifier.dart';
import '../../vibe_transfer/providers/vibe_transfer_notifier.dart';
import '../../tools/director_tools/providers/director_tools_notifier.dart';
import '../../tools/enhance/providers/enhance_notifier.dart';
import 'package:dio/dio.dart';
import '../services/metadata_import_service.dart';
import '../services/session_snapshot_service.dart';
import '../services/character_manager.dart';
import '../services/preset_service.dart';

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
  final bool showBgRemovalButton;
  final bool showUpscaleButton;
  final bool showEnhanceButton;
  final bool showDirectorToolsButton;
  final bool furryMode;
  final String? errorMessage;
  final int? anlas;
  final String characterEditorMode;
  final List<CharacterPreset> characterPresets;

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
    this.showBgRemovalButton = true,
    this.showUpscaleButton = true,
    this.showEnhanceButton = false,
    this.showDirectorToolsButton = false,
    this.furryMode = false,
    this.errorMessage,
    this.anlas,
    this.characterEditorMode = 'expanded',
    this.characterPresets = const [],
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
    bool? showBgRemovalButton,
    bool? showUpscaleButton,
    bool? showEnhanceButton,
    bool? showDirectorToolsButton,
    bool? furryMode,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? anlas,
    bool clearAnlas = false,
    String? characterEditorMode,
    List<CharacterPreset>? characterPresets,
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
      showBgRemovalButton: showBgRemovalButton ?? this.showBgRemovalButton,
      showUpscaleButton: showUpscaleButton ?? this.showUpscaleButton,
      showEnhanceButton: showEnhanceButton ?? this.showEnhanceButton,
      showDirectorToolsButton: showDirectorToolsButton ?? this.showDirectorToolsButton,
      furryMode: furryMode ?? this.furryMode,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      anlas: clearAnlas ? null : (anlas ?? this.anlas),
      characterEditorMode: characterEditorMode ?? this.characterEditorMode,
      characterPresets: characterPresets ?? this.characterPresets,
    );
  }
}

class GenerationNotifier extends ChangeNotifier {
  GenerationState _state = GenerationState();
  GenerationState get state => _state;

  late NovelAIService _service;
  NovelAIService get service => _service;
  late final WildcardProcessor _wildcardProcessor;
  final TagService _tagService;
  final WildcardService _wildcardService;
  final PreferencesService _prefs;
  String _outputDir;
  GalleryNotifier? _galleryNotifier;
  DirectorRefNotifier? _directorRefNotifier;
  VibeTransferNotifier? _vibeTransferNotifier;
  DirectorToolsNotifier? _directorToolsNotifier;
  EnhanceNotifier? _enhanceNotifier;

  // Extracted services
  final MetadataImportService _metadataImportService = MetadataImportService();
  late final SessionSnapshotService _sessionService;
  late final CharacterManager _characterManager;
  late final PresetFileService _presetService;

  TagService get tagService => _tagService;
  WildcardService get wildcardService => _wildcardService;
  String get presetsFilePath => _presetService.presetsFilePath;
  String get stylesFilePath => _presetService.stylesFilePath;

  Map<String, dynamic>? _lastMetadata;
  bool _imageSaved = false;
  bool get imageSaved => _imageSaved;

  Timer? _tagDebounce;
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
    required TagService tagService,
    required WildcardService wildcardService,
    required String outputDir,
    required String presetsFilePath,
    required String stylesFilePath,
    GalleryNotifier? galleryNotifier,
  }) : _prefs = preferences,
       _tagService = tagService,
       _wildcardService = wildcardService,
       _outputDir = outputDir,
       _galleryNotifier = galleryNotifier {
    _service = NovelAIService('');
    _wildcardProcessor = WildcardProcessor(wildcardDir: wildcardService.wildcardDir, wildcardService: _wildcardService);
    _presetService = PresetFileService(presetsFilePath: presetsFilePath, stylesFilePath: stylesFilePath);
    _sessionService = SessionSnapshotService(
      sessionFilePath: p.join(p.dirname(presetsFilePath), 'session_snapshot.json'),
    );
    _characterManager = CharacterManager(prefs: _prefs);
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

  void updateDirectorToolsNotifier(DirectorToolsNotifier notifier) {
    _directorToolsNotifier = notifier;
    notifier.updateService(_service);
  }

  void updateEnhanceNotifier(EnhanceNotifier notifier) {
    _enhanceNotifier = notifier;
    notifier.updateService(_service);
  }

  void setOutputDir(String dir) {
    _outputDir = dir;
  }

  Future<void> _loadInitialData() async {
    await _tagService.loadTags();
    await _wildcardService.refresh();
    final presets = await _presetService.loadPresets();
    final styles = await _presetService.loadStyles();

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
    _directorToolsNotifier?.updateService(_service);
    _enhanceNotifier?.updateService(_service);

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
      showBgRemovalButton: _prefs.showBgRemovalButton,
      showUpscaleButton: _prefs.showUpscaleButton,
      showEnhanceButton: _prefs.showEnhanceButton,
      showDirectorToolsButton: _prefs.showDirectorToolsButton,
      furryMode: _prefs.furryMode,
      characterEditorMode: _prefs.characterEditorMode,
    );
    loadCharacterPresets();
    notifyListeners();

    await _restoreSessionSnapshot();
    _sessionReady = true;

    fetchAnlas();
  }

  Future<void> fetchAnlas() async {
    final balance = await _service.getAnlasBalance();
    _state = _state.copyWith(anlas: balance, clearAnlas: balance == null);
    notifyListeners();
  }

  Future<void> reloadPresetsAndStyles() async {
    final presets = await _presetService.loadPresets();
    final styles = await _presetService.loadStyles();
    _state = _state.copyWith(presets: presets, styles: styles);
    notifyListeners();
  }

  Future<void> updateApiKey(String key) async {
    await _prefs.setApiKey(key);
    _service = NovelAIService(key);
    _vibeTransferNotifier?.updateService(_service);
    _directorToolsNotifier?.updateService(_service);
    _enhanceNotifier?.updateService(_service);
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

  Future<void> toggleShowBgRemovalButton() async {
    final newVal = !_state.showBgRemovalButton;
    await _prefs.setShowBgRemovalButton(newVal);
    _state = _state.copyWith(showBgRemovalButton: newVal);
    notifyListeners();
  }

  Future<void> toggleShowUpscaleButton() async {
    final newVal = !_state.showUpscaleButton;
    await _prefs.setShowUpscaleButton(newVal);
    _state = _state.copyWith(showUpscaleButton: newVal);
    notifyListeners();
  }

  Future<void> toggleShowEnhanceButton() async {
    final newVal = !_state.showEnhanceButton;
    await _prefs.setShowEnhanceButton(newVal);
    _state = _state.copyWith(showEnhanceButton: newVal);
    notifyListeners();
  }

  Future<void> toggleShowDirectorToolsButton() async {
    final newVal = !_state.showDirectorToolsButton;
    await _prefs.setShowDirectorToolsButton(newVal);
    _state = _state.copyWith(showDirectorToolsButton: newVal);
    notifyListeners();
  }

  void setLoading(bool value) {
    _state = _state.copyWith(isLoading: value);
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
    bool? furryMode,
  }) {
    if (furryMode != null) _prefs.setFurryMode(furryMode);
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
      furryMode: furryMode,
    );
    notifyListeners();
  }

  void addCharacter({String name = ''}) {
    final result = _characterManager.addCharacter(_state.characters, name: name);
    if (result == null) return;
    _state = _state.copyWith(characters: result);
    notifyListeners();
  }

  void updateCharacter(int index, NaiCharacter character) {
    final result = _characterManager.updateCharacter(_state.characters, index, character);
    if (result == null) return;
    _state = _state.copyWith(characters: result);
    notifyListeners();
  }

  void removeCharacter(int index) {
    final result = _characterManager.removeCharacter(
      _state.characters, _state.interactions, index);
    if (result == null) return;
    _state = _state.copyWith(
      characters: result.characters,
      interactions: result.interactions,
    );
    notifyListeners();
  }

  void updateInteraction(NaiInteraction interaction, {NaiInteraction? replacing}) {
    final updated = _characterManager.updateInteraction(
      _state.interactions, interaction, replacing: replacing);
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

  void removeInteraction(NaiInteraction interaction) {
    final updated = _characterManager.removeInteraction(_state.interactions, interaction);
    _state = _state.copyWith(interactions: updated);
    notifyListeners();
  }

  // — Character Editor Mode —

  Future<void> setCharacterEditorMode(String mode) async {
    await _prefs.setCharacterEditorMode(mode);
    _state = _state.copyWith(characterEditorMode: mode);
    notifyListeners();
  }

  // — Character Presets —

  void loadCharacterPresets() {
    final presets = _characterManager.loadPresets();
    if (presets.isEmpty) return;
    _state = _state.copyWith(characterPresets: presets);
  }

  Future<void> saveCharacterPreset(CharacterPreset preset) async {
    final updated = List<CharacterPreset>.from(_state.characterPresets)
      ..add(preset);
    _state = _state.copyWith(characterPresets: updated);
    notifyListeners();
    await _characterManager.persistPresets(updated);
  }

  Future<void> deleteCharacterPreset(String id) async {
    final updated = List<CharacterPreset>.from(_state.characterPresets)
      ..removeWhere((p) => p.id == id);
    _state = _state.copyWith(characterPresets: updated);
    notifyListeners();
    await _characterManager.persistPresets(updated);
  }

  void applyCharacterPreset(int charIndex, CharacterPreset preset) {
    final result = _characterManager.applyCharacterPreset(
      _state.characters, charIndex, preset);
    if (result == null) return;
    _state = _state.copyWith(characters: result);
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
      final resolvedPrompt = _tagService.resolveAliases(processedPrompt);

      String finalPrompt = resolvedPrompt;
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
          } catch (e) {
            debugPrint('GenerationNotifier.generate: $e');
          }
        }

        if (prefixes.isNotEmpty) combinedPrefix = prefixes.join("");
        if (suffixes.isNotEmpty) combinedSuffix = suffixes.join("");
        if (negatives.isNotEmpty) styleNegativeContent = negatives.join("");
      }

      if (_state.furryMode) {
        combinedPrefix = "fur dataset, ${combinedPrefix ?? ''}";
      }

      String baseNegative = _tagService.resolveAliases(negativePromptController.text);
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
        characters: _state.characters.map((c) => c.copyWith(
          prompt: _tagService.resolveAliases(c.prompt),
          uc: _tagService.resolveAliases(c.uc),
        )).toList(),
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
      fetchAnlas();
    }
  }

  Future<File?> _saveToDisk(Uint8List bytes, Map<String, dynamic> metadata, {String prefix = 'Gen', String? timestamp}) async {
    try {
      final directory = Directory(_outputDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final ts = timestamp ?? DateFormat('yyyyMMdd_HHmmssSSS').format(DateTime.now());
      final filePath = p.join(directory.path, '${prefix}_$ts.png');

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

  /// Parse metadata from a PNG file without applying it to state.
  Future<MetadataImportResult> parseImageMetadata(File file) async {
    return _metadataImportService.parseImageMetadata(
      file, smartStyleImport: _prefs.smartStyleImport);
  }

  /// Apply a parsed metadata result, importing only the selected categories.
  void applyImportedMetadata(MetadataImportResult result, Set<ImportCategory> categories) {
    if (categories.contains(ImportCategory.prompt)) {
      promptController.value = TextEditingValue(
        text: result.prompt,
        selection: TextSelection.collapsed(offset: result.prompt.length),
      );
    }
    if (categories.contains(ImportCategory.negativePrompt)) {
      negativePromptController.value = TextEditingValue(
        text: result.negativePrompt,
        selection: TextSelection.collapsed(offset: result.negativePrompt.length),
      );
    }
    if (categories.contains(ImportCategory.seed) && result.seed != null) {
      seedController.text = result.seed!;
    }

    _state = _state.copyWith(
      width: categories.contains(ImportCategory.settings) ? result.width : null,
      height: categories.contains(ImportCategory.settings) ? result.height : null,
      scale: categories.contains(ImportCategory.settings) ? result.scale : null,
      steps: categories.contains(ImportCategory.settings) ? result.steps : null,
      sampler: categories.contains(ImportCategory.settings) ? result.sampler : null,
      smea: categories.contains(ImportCategory.settings) ? result.smea : null,
      smeaDyn: categories.contains(ImportCategory.settings) ? result.smeaDyn : null,
      decrisper: categories.contains(ImportCategory.settings) ? result.decrisper : null,
      randomizeSeed: categories.contains(ImportCategory.seed) ? false : null,
      generatedImage: result.imageBytes,
      activeStyleNames: categories.contains(ImportCategory.styles) ? result.activeStyleNames : null,
      isStyleEnabled: categories.contains(ImportCategory.styles) ? result.isStyleEnabled : null,
      characters: categories.contains(ImportCategory.characters) ? result.characters : null,
      interactions: categories.contains(ImportCategory.characters) ? result.interactions : null,
      autoPositioning: categories.contains(ImportCategory.characters) ? result.autoPositioning : null,
    );
    notifyListeners();
  }

  /// Import all metadata from a PNG file (used by drag-and-drop).
  Future<void> importImageMetadata(File file) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final result = await parseImageMetadata(file);
      applyImportedMetadata(result, ImportCategory.values.toSet());
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
    await _presetService.savePresets(updatedPresets);
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
    final presets = await _presetService.loadPresets();
    _state = _state.copyWith(presets: presets);
    notifyListeners();
  }

  Future<void> refreshStyles() async {
    final styles = await _presetService.loadStyles();
    _state = _state.copyWith(styles: styles);
    notifyListeners();
  }

  Future<void> deletePreset(int index) async {
    final updatedPresets =
        List<GenerationPreset>.from(_state.presets)..removeAt(index);
    _state = _state.copyWith(presets: updatedPresets);
    notifyListeners();
    await _presetService.savePresets(updatedPresets);
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

      final cascadePrompt = _state.furryMode
          ? "fur dataset, ${request.baseCaption}"
          : request.baseCaption;

      final result = await _service.generateImage(
        prompt: cascadePrompt,
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
      fetchAnlas();
    }
  }

  Future<Uint8List?> generateImg2Img(Img2ImgRequest request, {Uint8List? sourceImageBytes}) async {
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
        final timestamp = DateFormat('yyyyMMdd_HHmmssSSS').format(DateTime.now());
        if (sourceImageBytes != null) {
          try {
            final directory = Directory(_outputDir);
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
            final srcPath = p.join(directory.path, 'Src_$timestamp.png');
            await File(srcPath).writeAsBytes(sourceImageBytes);
          } catch (e) {
            debugPrint("Source image save error: $e");
          }
        }
        final savedFile = await _saveToDisk(finalBytes, result.metadata, timestamp: timestamp);
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
      fetchAnlas();
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
    final snapshot = SessionSnapshot(
      prompt: promptController.text,
      negativePrompt: negativePromptController.text,
      seed: seedController.text,
      width: _state.width,
      height: _state.height,
      scale: _state.scale,
      steps: _state.steps,
      sampler: _state.sampler,
      smea: _state.smea,
      smeaDyn: _state.smeaDyn,
      decrisper: _state.decrisper,
      randomizeSeed: _state.randomizeSeed,
      autoPositioning: _state.autoPositioning,
      activeStyleNames: _state.activeStyleNames,
      isStyleEnabled: _state.isStyleEnabled,
      furryMode: _state.furryMode,
      characters: _state.characters,
      interactions: _state.interactions,
      directorReferences: _directorRefNotifier?.references.toList() ?? [],
      vibeTransfers: _vibeTransferNotifier?.vibes.toList() ?? [],
    );
    await _sessionService.save(snapshot);
  }

  Future<void> _restoreSessionSnapshot() async {
    if (!_prefs.rememberSession) return;
    final snapshot = await _sessionService.restore();
    if (snapshot == null) return;

    promptController.text = snapshot.prompt;
    negativePromptController.text = snapshot.negativePrompt;
    seedController.text = snapshot.seed;

    _state = _state.copyWith(
      width: snapshot.width,
      height: snapshot.height,
      scale: snapshot.scale,
      steps: snapshot.steps,
      sampler: snapshot.sampler,
      smea: snapshot.smea,
      smeaDyn: snapshot.smeaDyn,
      decrisper: snapshot.decrisper,
      randomizeSeed: snapshot.randomizeSeed,
      autoPositioning: snapshot.autoPositioning,
      activeStyleNames: snapshot.activeStyleNames,
      isStyleEnabled: snapshot.isStyleEnabled,
      furryMode: snapshot.furryMode,
      characters: snapshot.characters,
      interactions: snapshot.interactions,
    );

    // Restore director references
    if (snapshot.directorReferences.isNotEmpty) {
      _directorRefNotifier?.setReferences(snapshot.directorReferences);
    }

    // Restore vibe transfers
    if (snapshot.vibeTransfers.isNotEmpty) {
      _vibeTransferNotifier?.setVibes(snapshot.vibeTransfers);
    }

    notifyListeners();
  }

  Future<void> deleteSessionSnapshot() async {
    await _sessionService.delete();
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

