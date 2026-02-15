import '../../../generation/models/nai_character.dart';
import '../../../../styles.dart';
import '../models/cascade_beat.dart';

class CascadeStitchedRequest {
  final String baseCaption;
  final List<NaiCharacter> characters;
  final String sampler;
  final int steps;
  final double scale;
  final int width;
  final int height;
  final bool useCoords;
  final String negativePrompt;

  CascadeStitchedRequest({
    required this.baseCaption,
    required this.characters,
    required this.sampler,
    required this.steps,
    required this.scale,
    required this.width,
    required this.height,
    this.useCoords = true,
    this.negativePrompt = "",
  });
}

class CascadeStitchingService {
  /// Renders a single [CascadeBeat] into a [CascadeStitchedRequest].
  ///
  /// [appearances] should be a list of character appearance strings (e.g. "1girl, miku, blue hair").
  /// The order of [appearances] must match the indices of the character slots in the beat.
  /// [globalStyle] is an optional style string from the style tool.
  /// [manualPrompt] is an optional additional prompt from the user during casting.
  static CascadeStitchedRequest render({
    required CascadeBeat beat,
    required List<String> appearances,
    String? globalStyle,
    String? manualPrompt,
    bool useCoords = true,
    List<String> activeStyleNames = const [],
    List<PromptStyle> availableStyles = const [],
  }) {
    if (appearances.length < beat.characterSlots.length) {
      throw ArgumentError(
          "Not enough character appearances provided. Expected ${beat.characterSlots.length}, got ${appearances.length}");
    }

    // Build the base caption: [ScenePrompt] + [ManualUserPrompt] + [UserGlobalStyle]
    final List<String> basePromptParts = [];
    if (beat.environmentTags.isNotEmpty) {
      basePromptParts.add(beat.environmentTags);
    }
    if (manualPrompt != null && manualPrompt.trim().isNotEmpty) {
      basePromptParts.add(manualPrompt.trim());
    }
    if (globalStyle != null && globalStyle.trim().isNotEmpty) {
      basePromptParts.add(globalStyle.trim());
    }
    // Apply style prefix/suffix
    String? stylePrefix;
    String? styleSuffix;
    final List<String> styleNegatives = [];
    for (final styleName in activeStyleNames) {
      try {
        final style = availableStyles.firstWhere((s) => s.name == styleName);
        if (style.prefix.isNotEmpty) stylePrefix = (stylePrefix ?? '') + style.prefix;
        if (style.suffix.isNotEmpty) styleSuffix = (styleSuffix ?? '') + style.suffix;
        if (style.negativeContent.isNotEmpty) styleNegatives.add(style.negativeContent);
      } catch (_) {}
    }

    final rawCaption = basePromptParts.join(", ");
    final String baseCaption = [
      if (stylePrefix != null) stylePrefix,
      rawCaption,
      if (styleSuffix != null) styleSuffix,
    ].join('');

    final String negativePrompt = styleNegatives.join('');

    // Build the NaiCharacter objects
    final List<NaiCharacter> characters = [];
    for (int i = 0; i < beat.characterSlots.length; i++) {
      final slot = beat.characterSlots[i];
      final appearance = appearances[i];

      // Final Character Prompt = [ActionTag] + [UserCharacterAppearance] + [SlotPositivePrompt]
      // Note: actionTag should be in format "source#action", "target#action", or "mutual#action"
      // NovelAIService handles these prefixes if they are in the character prompt.
      final List<String> charPromptParts = [];
      if (slot.actionTag != null && slot.actionTag!.isNotEmpty) {
        charPromptParts.add(slot.actionTag!);
      }
      if (appearance.trim().isNotEmpty) {
        charPromptParts.add(appearance.trim());
      }
      if (slot.positivePrompt.trim().isNotEmpty) {
        charPromptParts.add(slot.positivePrompt.trim());
      }
      final String characterPrompt = charPromptParts.join(", ");

      characters.add(NaiCharacter(
        prompt: characterPrompt,
        uc: slot.negativePrompt,
        center: slot.position,
      ));
    }

    return CascadeStitchedRequest(
      baseCaption: baseCaption,
      characters: characters,
      sampler: beat.sampler,
      steps: beat.steps,
      scale: beat.scale,
      width: beat.width,
      height: beat.height,
      useCoords: useCoords,
      negativePrompt: negativePrompt,
    );
  }
}
