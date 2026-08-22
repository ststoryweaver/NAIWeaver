import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/services/styles.dart';
import '../models/nai_character.dart';

/// Categories of metadata that can be selectively imported.
enum ImportCategory { prompt, negativePrompt, characters, seed, styles, settings }

/// Result of fuzzy-matching styles against a composed prompt.
class StyleMatchResult {
  final List<String> matchedStyleNames;
  final String cleanedPrompt;
  final String cleanedNegativePrompt;
  final bool anyMatched;

  StyleMatchResult({
    required this.matchedStyleNames,
    required this.cleanedPrompt,
    required this.cleanedNegativePrompt,
    required this.anyMatched,
  });
}

/// Result of parsing image metadata from a PNG file.
class MetadataImportResult {
  final String prompt;
  final String negativePrompt;
  final String? seed;
  final double? width;
  final double? height;
  final double? scale;
  final double? steps;
  final String? sampler;
  final bool? smea;
  final bool? smeaDyn;
  final bool? decrisper;

  /// Raw NovelAI model id from the Comment JSON (`model`), if present.
  final String? model;
  final List<String>? activeStyleNames;
  final bool? isStyleEnabled;
  final List<NaiCharacter> characters;
  final List<NaiInteraction> interactions;
  final bool? autoPositioning;
  final Uint8List imageBytes;
  final bool isFuzzyMatched;

  MetadataImportResult({
    required this.prompt,
    required this.negativePrompt,
    this.seed,
    this.width,
    this.height,
    this.scale,
    this.steps,
    this.sampler,
    this.smea,
    this.smeaDyn,
    this.decrisper,
    this.model,
    this.activeStyleNames,
    this.isStyleEnabled,
    this.characters = const [],
    this.interactions = const [],
    this.autoPositioning,
    required this.imageBytes,
    this.isFuzzyMatched = false,
  });

  /// Determines which import categories have data in this result.
  Set<ImportCategory> get availableCategories {
    final cats = <ImportCategory>{};
    if (prompt.isNotEmpty) cats.add(ImportCategory.prompt);
    if (negativePrompt.isNotEmpty) cats.add(ImportCategory.negativePrompt);
    if (characters.isNotEmpty) cats.add(ImportCategory.characters);
    if (seed != null) cats.add(ImportCategory.seed);
    if (activeStyleNames != null) cats.add(ImportCategory.styles);
    if (width != null || scale != null || steps != null || sampler != null || model != null) cats.add(ImportCategory.settings);
    return cats;
  }
}

/// Service that extracts metadata from PNG image files and returns a
/// structured [MetadataImportResult] without mutating any UI state.
class MetadataImportService {
  /// Try to match a composed prompt against available styles by checking
  /// prefix/suffix content. Strips matched content from the prompt.
  static String _norm(String s) => s.toLowerCase().trim().replaceAll(RegExp(r',\s*$'), '');

  static StyleMatchResult tryMatchStyles({
    required String composedPrompt,
    required String composedNegativePrompt,
    required List<PromptStyle> availableStyles,
  }) {
    final matched = <String>{};
    var prompt = composedPrompt;
    var negative = composedNegativePrompt;

    // Multiple passes: styles may be composed in any order, so a single
    // pass can miss styles whose prefix/suffix is hidden behind another
    // style's content. Loop until no new matches are found.
    bool foundNew = true;
    while (foundNew) {
      foundNew = false;
      for (final style in availableStyles) {
        if (matched.contains(style.name)) continue;
        bool didMatch = false;

        // Prefix match (case-insensitive, whitespace-normalized)
        if (style.prefix.isNotEmpty) {
          final np = _norm(prompt);
          final ns = _norm(style.prefix);
          if (np.startsWith(ns)) {
            prompt = prompt.substring(style.prefix.length).trimLeft();
            if (prompt.startsWith(',')) prompt = prompt.substring(1).trimLeft();
            didMatch = true;
          }
        }

        // Suffix match (case-insensitive, whitespace-normalized)
        if (style.suffix.isNotEmpty) {
          final np = _norm(prompt);
          final ns = _norm(style.suffix);
          if (np.endsWith(ns)) {
            prompt = prompt.substring(0, prompt.length - style.suffix.length).trimRight();
            if (prompt.endsWith(',')) prompt = prompt.substring(0, prompt.length - 1).trimRight();
            didMatch = true;
          }
        }

        // Negative match (case-insensitive)
        if (style.negativeContent.isNotEmpty) {
          final idx = negative.toLowerCase().indexOf(style.negativeContent.toLowerCase());
          if (idx >= 0) {
            negative = negative.substring(0, idx) + negative.substring(idx + style.negativeContent.length);
            negative = negative.replaceAll(RegExp(r',\s*,'), ',');
            negative = negative.replaceAll(RegExp(r'^\s*,\s*'), '');
            negative = negative.replaceAll(RegExp(r'\s*,\s*$'), '');
            negative = negative.trim();
            didMatch = true;
          }
        }

        if (didMatch) {
          matched.add(style.name);
          foundNew = true;
        }
      }
    }

    return StyleMatchResult(
      matchedStyleNames: matched.toList(),
      cleanedPrompt: prompt,
      cleanedNegativePrompt: negative,
      anyMatched: matched.isNotEmpty,
    );
  }

  /// Parse metadata from an image file (PNG, WebP, JPEG).
  /// [smartStyleImport] controls whether to use original prompts or composed prompts.
  Future<MetadataImportResult> parseImageMetadata(
    File file, {
    required bool smartStyleImport,
    List<PromptStyle> availableStyles = const [],
  }) async {
    final bytes = await file.readAsBytes();
    final metadata = await compute(extractMetadata, bytes);

    if (metadata == null || metadata.isEmpty) {
      throw Exception("No metadata found");
    }

    String? prompt;
    String? negativePrompt;
    Map<String, dynamic>? settings;

    // NovelAI stores generation parameters in the 'Comment' field as JSON
    if (metadata.containsKey('Comment')) {
      settings = parseCommentJson(metadata['Comment']!);

      if (settings != null) {
        // Check if style metadata was saved with this image
        final savedStyleNames = settings['active_style_names'];

        if (smartStyleImport &&
            savedStyleNames is List &&
            savedStyleNames.isNotEmpty) {
          // Smart import: use original prompt (without style prefix/suffix)
          prompt = settings['original_prompt'] ?? settings['prompt'];
          negativePrompt =
              settings['original_negative_prompt'] ?? settings['uc'];
        } else {
          // Raw import or legacy: use composed prompt as-is
          prompt = settings['prompt'];
          prompt ??= settings['original_prompt'];
          negativePrompt = settings['uc'];
        }

        negativePrompt ??= settings['undesired_content'];

        // Deep extraction for V4.5 structure if direct keys are missing
        if (negativePrompt == null || negativePrompt.isEmpty) {
          negativePrompt =
              settings['v4_negative_prompt']?['caption']?['base_caption'];
        }
      }
    }

    // If prompt is still missing, try Description (standard PNG chunk)
    prompt ??= metadata['Description'];

    if (prompt == null) {
      throw Exception("No metadata found");
    }

    // Build result fields from settings
    String? seed;
    double? width, height, scale, steps;
    String? sampler;
    String? model;
    bool? smea, smeaDyn, decrisper;
    List<String>? activeStyleNames;
    bool? isStyleEnabled;
    List<NaiCharacter> characters = const [];
    List<NaiInteraction> interactions = const [];
    bool? autoPositioning;
    bool isFuzzy = false;

    if (settings != null) {
      width = (settings['width'] as num?)?.toDouble();
      height = (settings['height'] as num?)?.toDouble();
      scale = (settings['scale'] as num?)?.toDouble();
      steps = (settings['steps'] as num?)?.toDouble();
      sampler = settings['sampler']?.toString();
      smea = settings['sm'] as bool?;
      smeaDyn = settings['sm_dyn'] as bool?;
      decrisper = settings['dynamic_thresholding'] as bool?;
      // Our own PNGs carry the wire id under `model` (since the V5 work);
      // NovelAI's own exports name it in `Source` ("NovelAI Diffusion V5 …").
      model = settings['model']?.toString() ??
          settings['model_name']?.toString() ??
          metadata['Source']?.toString();
      if (settings['seed'] != null) seed = settings['seed'].toString();

      // Restore active styles based on smart import toggle
      final savedStyleNames = settings['active_style_names'];
      final savedStyleEnabled = settings['is_style_enabled'];
      if (smartStyleImport &&
          savedStyleNames is List &&
          savedStyleNames.isNotEmpty) {
        // Smart: restore style selections so re-generation applies them
        activeStyleNames = savedStyleNames.cast<String>().toList();
        isStyleEnabled = savedStyleEnabled == true;
      } else if (smartStyleImport && availableStyles.isNotEmpty) {
        // Legacy/external: fuzzy-match prompt against available styles
        final match = tryMatchStyles(
          composedPrompt: prompt,
          composedNegativePrompt: negativePrompt ?? '',
          availableStyles: availableStyles,
        );
        if (match.anyMatched) {
          activeStyleNames = match.matchedStyleNames;
          isStyleEnabled = true;
          prompt = match.cleanedPrompt;
          negativePrompt = match.cleanedNegativePrompt;
          isFuzzy = true;
        } else {
          activeStyleNames = <String>[];
          isStyleEnabled = false;
        }
      } else {
        // Raw or legacy: styles are baked into the prompt, disable to avoid doubling
        activeStyleNames = <String>[];
        isStyleEnabled = false;
      }

      // Restore characters from V4 prompt metadata
      final v4Prompt = settings['v4_prompt'];
      final v4Negative = settings['v4_negative_prompt'];
      if (v4Prompt is Map) {
        final charCaptions = v4Prompt['caption']?['char_captions'];
        if (charCaptions is List && charCaptions.isNotEmpty) {
          final negCaption =
              (v4Negative is Map) ? v4Negative['caption'] : null;
          final negCharCaptions =
              (negCaption is Map) ? negCaption['char_captions'] as List? : null;

          final interactionPattern =
              RegExp(r'^(source|target|mutual)#([^,]+),\s*');
          final parsedCharacters = <NaiCharacter>[];
          final rawTags =
              <({int charIndex, String type, String action})>[];

          for (int i = 0; i < charCaptions.length; i++) {
            final cc = charCaptions[i] as Map<String, dynamic>;
            final centers = cc['centers'] as List?;
            final center = (centers != null && centers.isNotEmpty)
                ? NaiCoordinate.fromJson(
                    Map<String, dynamic>.from(centers.first as Map))
                : NaiCoordinate(x: 0.5, y: 0.5);

            String uc = '';
            if (negCharCaptions != null && i < negCharCaptions.length) {
              uc = (negCharCaptions[i]
                      as Map<String, dynamic>)['char_caption'] ??
                  '';
            }

            // Extract and strip interaction prefixes from char_caption
            String caption = cc['char_caption'] ?? '';
            while (true) {
              final match = interactionPattern.firstMatch(caption);
              if (match == null) break;
              rawTags.add((
                charIndex: i,
                type: match.group(1)!,
                action: match.group(2)!,
              ));
              caption = caption.substring(match.end);
            }

            parsedCharacters.add(NaiCharacter(
              prompt: caption,
              uc: uc,
              center: center,
            ));
          }

          // Build NaiInteraction objects by grouping chars with the same (type, action)
          final parsedInteractions = <NaiInteraction>[];
          final actionGroups = <String,
              ({List<int> sources, List<int> targets, List<int> mutuals})>{};

          for (final tag in rawTags) {
            final group = actionGroups.putIfAbsent(
              tag.action,
              () =>
                  (sources: <int>[], targets: <int>[], mutuals: <int>[]),
            );
            if (tag.type == 'source') {
              group.sources.add(tag.charIndex);
            } else if (tag.type == 'target') {
              group.targets.add(tag.charIndex);
            } else if (tag.type == 'mutual') {
              group.mutuals.add(tag.charIndex);
            }
          }

          for (final entry in actionGroups.entries) {
            final g = entry.value;
            if (g.sources.isNotEmpty && g.targets.isNotEmpty) {
              parsedInteractions.add(NaiInteraction(
                sourceCharacterIndices: g.sources,
                targetCharacterIndices: g.targets,
                actionName: entry.key,
                type: InteractionType.sourceTarget,
              ));
            }
            if (g.mutuals.isNotEmpty) {
              parsedInteractions.add(NaiInteraction(
                sourceCharacterIndices: g.mutuals,
                targetCharacterIndices: [],
                actionName: entry.key,
                type: InteractionType.mutual,
              ));
            }
          }

          final useCoords = v4Prompt['use_coords'] as bool? ?? false;
          characters = parsedCharacters;
          interactions = parsedInteractions;
          autoPositioning = !useCoords;
        }
      } else {
        characters = [];
        interactions = [];
      }
    }

    return MetadataImportResult(
      prompt: prompt,
      negativePrompt: negativePrompt ?? '',
      seed: seed,
      width: width,
      height: height,
      scale: scale,
      steps: steps,
      sampler: sampler,
      smea: smea,
      smeaDyn: smeaDyn,
      decrisper: decrisper,
      model: model,
      activeStyleNames: activeStyleNames,
      isStyleEnabled: isStyleEnabled,
      characters: characters,
      interactions: interactions,
      autoPositioning: autoPositioning,
      imageBytes: bytes,
      isFuzzyMatched: isFuzzy,
    );
  }
}
