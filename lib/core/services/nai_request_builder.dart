import '../../features/generation/models/nai_character.dart';
import '../models/nai_model.dart';

/// Strips backslashes from a prompt before it reaches the NovelAI API.
/// NovelAI prompts have no use for `\` (it's not an escape or weighting
/// character in their syntax), and stray backslashes — usually pasted in by
/// accident from other tooling — only pollute the prompt. Done here, at the
/// single API chokepoint, so every path (txt2img, img2img, characters) is
/// covered. Returns an empty string for null input.
String sanitizePromptForNai(String? prompt) =>
    (prompt ?? '').replaceAll('\\', '');

/// Pure builder for the `/ai/generate-image` request body.
///
/// This is the per-model sanitizer NovelAI's own frontend applies before it
/// POSTs (research doc §2.3), expressed as data from [NaiCaps]:
///
/// * V4.5 bodies are unchanged from what this app has always sent, except
///   that `sm` / `sm_dyn` are forced false (sending `true` returns HTTP 500
///   on every V4+ model).
/// * `noise_schedule` is honoured only where the model offers a picker
///   (V4.5); V5 always gets its forced default. `cfg_rescale` and
///   `skip_cfg_above_sigma` (Variety+) are emitted only for models whose caps
///   allow them — V5 drops Variety+ at launch.
/// * V5 bodies drop `sm`/`sm_dyn` entirely, force `noise_schedule: karras`,
///   drop the Vibe Transfer / Director Reference arrays (not supported at
///   launch), send `params_version: 4`, raw 3-dp character centers, and emit
///   the alpha fields only when transparency is requested.
///
/// No I/O, no Flutter — unit-testable.
Map<String, dynamic> buildNaiGenerateBody({
  required NaiModel model,
  required String prompt,
  required int width,
  required int height,
  required int seed,
  int steps = 28,
  double scale = 6.0,
  String sampler = 'k_euler_ancestral',
  String? negativePrompt,
  bool smea = false,
  bool smeaDyn = false,
  bool decrisper = false,
  String? noiseSchedule,
  double? cfgRescale,
  double? varietyBoostSigma,
  String? promptPrefix,
  String? promptSuffix,
  List<NaiCharacter> characters = const [],
  List<NaiInteraction> interactions = const [],
  String action = 'generate',
  String? sourceImageBase64,
  String? maskBase64,
  double? img2imgStrength,
  double? img2imgNoise,
  int? maskBlur,
  List<String>? directorRefImages,
  List<Map<String, dynamic>>? directorRefDescriptions,
  List<double>? directorRefStrengths,
  List<double>? directorRefSecondaryStrengths,
  List<double>? directorRefInfoExtracted,
  List<String>? vibeTransferImages,
  List<double>? vibeTransferStrengths,
  List<double>? vibeTransferInfoExtracted,
  bool? useCoords,
  bool transparentBackground = false,
}) {
  // V5 Curated inpainting is routed to the V4.5 Curated wire model, so the
  // body must be V4.5-shaped as well; every other action shapes for `model`.
  final bodyModel = model.bodyModelFor(action);
  final caps = bodyModel.caps;
  final transparent = transparentBackground && caps.transparency;

  // NovelAI prepends `transparent background` to the quality suffix when the
  // Transparent BG toggle is on; we slot it between the prompt and the style
  // suffix so it lands in the same place.
  final alphaTag = transparent ? ', transparent background' : '';
  String inputPrompt = sanitizePromptForNai(
      '${promptPrefix ?? ''}$prompt$alphaTag${promptSuffix ?? ''}');
  if (caps.autoText) {
    inputPrompt = applyAutoText(inputPrompt);
  }

  final effectiveNegativePrompt = sanitizePromptForNai(negativePrompt);

  // Cap characters at what the model accepts.
  final effectiveCharacters = characters.length > caps.maxCharacters
      ? characters.sublist(0, caps.maxCharacters)
      : characters;
  final bool isMultiCharacter = effectiveCharacters.isNotEmpty;

  Map<String, dynamic> centerJson(NaiCoordinate c) => caps.freeformPosition
      ? {'x': _round3(c.x), 'y': _round3(c.y)}
      : c.toJson();

  // Build character captions with interaction tags
  final List<Map<String, dynamic>> charCaptions = [];
  for (int i = 0; i < effectiveCharacters.length; i++) {
    final character = effectiveCharacters[i];
    String caption = character.prompt;

    for (final interaction in interactions) {
      if (interaction.type == InteractionType.mutual) {
        if (interaction.sourceCharacterIndices.contains(i)) {
          caption = 'mutual#${interaction.actionName}, $caption';
        }
      } else {
        if (interaction.sourceCharacterIndices.contains(i)) {
          caption = 'source#${interaction.actionName}, $caption';
        } else if (interaction.targetCharacterIndices.contains(i)) {
          caption = 'target#${interaction.actionName}, $caption';
        }
      }
    }

    charCaptions.add({
      'char_caption': sanitizePromptForNai(caption),
      'centers': [centerJson(character.center)],
    });
  }

  // DDIM is silently remapped to Euler Ancestral on V4/V5 by NovelAI's UI.
  final effectiveSampler = sampler == 'ddim' ? 'k_euler_ancestral' : sampler;

  final sendDirector = caps.characterReference &&
      directorRefImages != null &&
      directorRefImages.isNotEmpty;
  // Vibe Transfer and Precise/Character Reference are mutually exclusive:
  // NovelAI's own UI hides Vibe once a Director reference is set, and sending
  // both produces a ZIP whose image entry is empty or truncated (issue #24) —
  // which used to be saved verbatim as a corrupt file. Director wins, matching
  // the frontend. On V5 both caps are false, so neither array is sent anyway.
  final sendVibes = caps.vibeTransfer &&
      !sendDirector &&
      vibeTransferImages != null &&
      vibeTransferImages.isNotEmpty;

  final parameters = <String, dynamic>{
    'params_version': bodyModel.defaults.paramsVersion,
    'width': width,
    'height': height,
    'scale': scale,
    'sampler': effectiveSampler,
    'steps': steps,
    'seed': seed,
    'n_samples': 1,
    // `caps.noiseSchedule` means "the user may pick one". When false (V5) the
    // frontend deletes the key and re-adds the forced default — so an
    // unsupported choice can never leak through. Unknown values fall back to
    // the model default rather than being passed to the API verbatim.
    'noise_schedule': caps.noiseSchedule
        ? (noiseSchedule != null &&
                bodyModel.noiseSchedules.contains(noiseSchedule)
            ? noiseSchedule
            : bodyModel.defaults.noiseSchedule)
        : bodyModel.defaults.noiseSchedule,
    // V4.5: keep the keys (byte-identical body) but never true.
    // V5: the frontend deletes them outright.
    if (!bodyModel.isV5) 'sm': caps.smea && smea,
    if (!bodyModel.isV5) 'sm_dyn': caps.smea && smeaDyn,
    'dynamic_thresholding': caps.decrisper && decrisper,
    // Prompt Guidance Rescale. Supported on V4.5 and V5 alike; 0 is NovelAI's
    // default and is sent explicitly, matching their frontend.
    if (caps.cfgRescale)
      'cfg_rescale': cfgRescale ?? bodyModel.defaults.cfgRescale,
    // Variety+ raises the sigma floor below which CFG is skipped. The
    // frontend sends null when the toggle is off, and deletes the key
    // entirely on models without the capability (V5 at launch).
    if (caps.varietyPlus) 'skip_cfg_above_sigma': varietyBoostSigma,
    'uc': effectiveNegativePrompt,
    if (isMultiCharacter)
      'characterPrompts': charCaptions.map((cc) {
        return {
          'prompt': cc['char_caption'],
          'center': (cc['centers'] as List).isNotEmpty
              ? (cc['centers'] as List).first
              : {'x': 0.5, 'y': 0.5},
        };
      }).toList(),
    'v4_prompt': {
      'caption': {
        'base_caption': inputPrompt,
        'char_captions': charCaptions,
      },
      'use_coords': useCoords ?? isMultiCharacter,
      'use_order': true,
    },
    'v4_negative_prompt': {
      'caption': {
        'base_caption': effectiveNegativePrompt,
        'char_captions': effectiveCharacters.map((c) {
          final neg = c.toV4NegativePrompt();
          final caption = neg['char_caption'];
          if (caption is String) {
            neg['char_caption'] = sanitizePromptForNai(caption);
          }
          neg['centers'] = [centerJson(c.center)];
          return neg;
        }).toList(),
      }
    },
    // V5-only extras, in the order NovelAI's frontend emits them.
    if (bodyModel.isV5 && effectiveSampler == 'k_euler_ancestral') ...{
      'deliberate_euler_ancestral_bug': false,
      'prefer_brownian': true,
    },
    if (transparent) ...{
      'straight_alpha': true,
      'tag_hint_transparent_background': true,
    },
    // img2img / inpainting parameters
    if (action != 'generate' && sourceImageBase64 != null)
      'image': sourceImageBase64,
    if (action != 'generate' && maskBase64 != null) 'mask': maskBase64,
    if (action != 'generate' && img2imgStrength != null)
      'strength': img2imgStrength,
    if (action == 'img2img' && img2imgNoise != null) 'noise': img2imgNoise,
    if (action == 'img2img') 'extra_noise_seed': seed,
    if (action != 'generate') 'add_original_image': true,
    if (action == 'infill' && maskBlur != null) 'mask_blur': maskBlur,
    // Director reference (Precise Reference) parameters
    if (sendDirector) 'director_reference_images': directorRefImages,
    if (sendDirector &&
        directorRefDescriptions != null &&
        directorRefDescriptions.isNotEmpty)
      'director_reference_descriptions': directorRefDescriptions,
    if (sendDirector &&
        directorRefStrengths != null &&
        directorRefStrengths.isNotEmpty)
      'director_reference_strength_values': directorRefStrengths,
    if (sendDirector &&
        directorRefSecondaryStrengths != null &&
        directorRefSecondaryStrengths.isNotEmpty)
      'director_reference_secondary_strength_values':
          directorRefSecondaryStrengths,
    if (sendDirector &&
        directorRefInfoExtracted != null &&
        directorRefInfoExtracted.isNotEmpty)
      'director_reference_information_extracted': directorRefInfoExtracted,
    // Vibe Transfer (Reference Image) parameters
    if (sendVibes) 'reference_image_multiple': vibeTransferImages,
    if (sendVibes &&
        vibeTransferStrengths != null &&
        vibeTransferStrengths.isNotEmpty)
      'reference_strength_multiple': vibeTransferStrengths,
    if (sendVibes &&
        vibeTransferInfoExtracted != null &&
        vibeTransferInfoExtracted.isNotEmpty)
      'reference_information_extracted_multiple': vibeTransferInfoExtracted,
  };

  return {
    'input': inputPrompt,
    'model': action == 'infill' ? model.inpaintingId : model.id,
    'action': action,
    'parameters': parameters,
  };
}

double _round3(double v) => (v * 1000).round() / 1000;

final RegExp _quotedText = RegExp(r'"([^"\n]+)"|「([^」\n]+)」');
final RegExp _hasTextBlock = RegExp(r'(^|\n)\s*Text:', caseSensitive: false);

/// NovelAI V5 "auto text": when the prompt quotes a string (`"..."` or
/// `「...」`) and has no explicit `Text:` block, the frontend appends
/// `\nText: <quoted>` so the model renders it. Multiple quoted strings are
/// joined with `, `. A manual `Text:` block disables the auto path.
String applyAutoText(String prompt) {
  if (_hasTextBlock.hasMatch(prompt)) return prompt;
  final quoted = _quotedText
      .allMatches(prompt)
      .map((m) => (m.group(1) ?? m.group(2) ?? '').trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (quoted.isEmpty) return prompt;
  return '$prompt\nText: ${quoted.join(', ')}';
}
