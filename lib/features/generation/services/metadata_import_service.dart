import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/utils/image_utils.dart';
import '../models/nai_character.dart';

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
  final List<String>? activeStyleNames;
  final bool? isStyleEnabled;
  final List<NaiCharacter> characters;
  final List<NaiInteraction> interactions;
  final bool? autoPositioning;
  final Uint8List imageBytes;

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
    this.activeStyleNames,
    this.isStyleEnabled,
    this.characters = const [],
    this.interactions = const [],
    this.autoPositioning,
    required this.imageBytes,
  });
}

/// Service that extracts metadata from PNG image files and returns a
/// structured [MetadataImportResult] without mutating any UI state.
class MetadataImportService {
  /// Parse metadata from a PNG image file.
  /// [smartStyleImport] controls whether to use original prompts or composed prompts.
  Future<MetadataImportResult> parseImageMetadata(
    File file, {
    required bool smartStyleImport,
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
    bool? smea, smeaDyn, decrisper;
    List<String>? activeStyleNames;
    bool? isStyleEnabled;
    List<NaiCharacter> characters = const [];
    List<NaiInteraction> interactions = const [];
    bool? autoPositioning;

    if (settings != null) {
      width = (settings['width'] as num?)?.toDouble();
      height = (settings['height'] as num?)?.toDouble();
      scale = (settings['scale'] as num?)?.toDouble();
      steps = (settings['steps'] as num?)?.toDouble();
      sampler = settings['sampler']?.toString();
      smea = settings['sm'] as bool?;
      smeaDyn = settings['sm_dyn'] as bool?;
      decrisper = settings['dynamic_thresholding'] as bool?;
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
      activeStyleNames: activeStyleNames,
      isStyleEnabled: isStyleEnabled,
      characters: characters,
      interactions: interactions,
      autoPositioning: autoPositioning,
      imageBytes: bytes,
    );
  }
}
