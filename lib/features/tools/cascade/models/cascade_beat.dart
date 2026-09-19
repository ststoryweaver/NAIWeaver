import 'dart:math';

import '../../../generation/models/nai_character.dart';

class BeatCharacterSlot {
  final NaiCoordinate position;

  /// Which cast member this slot renders. Cast-time appearances
  /// ([CascadeState.characterAppearances]) are keyed by this index, so a slot
  /// keeps its character when other slots on the beat are removed or
  /// reordered. Legacy beats without the field fall back to slot position.
  final int castIndex;

  /// The action tags for this slot, e.g. "source#hugging", "target#hugging",
  /// "mutual#holding hands". A slot can hold multiple interactions at once
  /// (e.g. a character that is the source of one action and the target of
  /// another). Empty when no interaction is defined for this slot.
  final List<String> actionTags;

  final String positivePrompt;
  final String negativePrompt;

  BeatCharacterSlot({
    required this.position,
    this.castIndex = 0,
    this.actionTags = const [],
    this.positivePrompt = "",
    this.negativePrompt = "",
  });

  /// [fallbackCastIndex] is the slot's position in its beat, used when the
  /// JSON predates per-slot cast identity.
  factory BeatCharacterSlot.fromJson(
    Map<String, dynamic> json, {
    int fallbackCastIndex = 0,
  }) {
    // Backward-compatible: detect the legacy single-string `actionTag` field
    // vs the new `actionTags` list. Old saved cascades carry `actionTag`.
    final List<String> tags;
    if (json.containsKey('actionTags')) {
      tags = (json['actionTags'] as List?)?.cast<String>() ?? const [];
    } else {
      final legacy = json['actionTag'] as String?;
      tags = (legacy != null && legacy.isNotEmpty) ? [legacy] : const [];
    }
    // Slots created before v0.9.5 defaulted to (2, 2), a placeholder outside
    // NovelAI's 0..1 coordinate space that was sent verbatim under manual
    // placement. Anything out of range is treated as "never positioned" and
    // lands on the centre, which is what new slots get.
    final rawPosition = NaiCoordinate.fromJson(json['position']);
    final inRange =
        rawPosition.x >= 0 &&
        rawPosition.x <= 1 &&
        rawPosition.y >= 0 &&
        rawPosition.y <= 1;
    return BeatCharacterSlot(
      position: inRange ? rawPosition : NaiCoordinate(x: 0.5, y: 0.5),
      castIndex: (json['castIndex'] as int?) ?? fallbackCastIndex,
      actionTags: tags,
      positivePrompt: json['positivePrompt'] ?? "",
      negativePrompt: json['negativePrompt'] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    'position': position.toJson(),
    'castIndex': castIndex,
    'actionTags': actionTags,
    'positivePrompt': positivePrompt,
    'negativePrompt': negativePrompt,
  };

  BeatCharacterSlot copyWith({
    NaiCoordinate? position,
    int? castIndex,
    List<String>? actionTags,
    String? positivePrompt,
    String? negativePrompt,
  }) {
    return BeatCharacterSlot(
      position: position ?? this.position,
      castIndex: castIndex ?? this.castIndex,
      actionTags: actionTags ?? this.actionTags,
      positivePrompt: positivePrompt ?? this.positivePrompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
    );
  }
}

class CascadeBeat {
  /// Stable across edits and reordering; clones receive a new identity.
  final String id;
  static final _random = Random.secure();

  static String _newId() => List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  final List<BeatCharacterSlot> characterSlots;

  /// Scene/action/composition tags for this beat (e.g. "2girls, hugging,
  /// wide shot, from above"). These feed the NovelAI **base prompt** and
  /// describe what is happening and how it is framed — distinct from
  /// [environmentTags], which describes *where* the scene takes place.
  /// They are concatenated ahead of the environment tags by the stitcher.
  final String sceneTags;

  final String environmentTags;

  // Per-beat generation settings
  final String sampler;
  final int steps;
  final double scale;
  final int width;
  final int height;
  final List<String> activeStyleNames;

  /// Per-beat override of [PromptCascade.useCoords]. `null` inherits the
  /// cascade-level setting so legacy beats keep their original behaviour.
  final bool? useCoords;

  CascadeBeat({
    String? id,
    required this.characterSlots,
    required this.environmentTags,
    this.sceneTags = "",
    this.sampler = "k_euler_ancestral",
    this.steps = 28,
    this.scale = 6.0,
    this.width = 832,
    this.height = 1216,
    this.activeStyleNames = const [],
    this.useCoords,
  }) : id = id ?? _newId();

  factory CascadeBeat.fromJson(
    Map<String, dynamic> json, {
    String? fallbackId,
  }) => CascadeBeat(
    id: json['id'] as String? ?? fallbackId,
    characterSlots: [
      for (final (i, e) in (json['characterSlots'] as List).indexed)
        BeatCharacterSlot.fromJson(e, fallbackCastIndex: i),
    ],
    sceneTags: json['sceneTags'] ?? "",
    environmentTags: json['environmentTags'],
    sampler: json['sampler'] ?? "k_euler_ancestral",
    steps: json['steps'] ?? 28,
    scale: (json['scale'] as num?)?.toDouble() ?? 6.0,
    width: json['width'] ?? 832,
    height: json['height'] ?? 1216,
    activeStyleNames: (json['activeStyleNames'] as List?)?.cast<String>() ?? [],
    useCoords: json['useCoords'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'characterSlots': characterSlots.map((e) => e.toJson()).toList(),
    'id': id,
    'sceneTags': sceneTags,
    'environmentTags': environmentTags,
    'sampler': sampler,
    'steps': steps,
    'scale': scale,
    'width': width,
    'height': height,
    'activeStyleNames': activeStyleNames,
    if (useCoords != null) 'useCoords': useCoords,
  };

  static const _unset = Object();

  CascadeBeat copyWith({
    List<BeatCharacterSlot>? characterSlots,
    String? sceneTags,
    String? environmentTags,
    String? sampler,
    int? steps,
    double? scale,
    int? width,
    int? height,
    List<String>? activeStyleNames,
    Object? useCoords = _unset,
  }) {
    return CascadeBeat(
      id: id,
      characterSlots: characterSlots ?? this.characterSlots,
      sceneTags: sceneTags ?? this.sceneTags,
      environmentTags: environmentTags ?? this.environmentTags,
      sampler: sampler ?? this.sampler,
      steps: steps ?? this.steps,
      scale: scale ?? this.scale,
      width: width ?? this.width,
      height: height ?? this.height,
      activeStyleNames: activeStyleNames ?? this.activeStyleNames,
      useCoords: identical(useCoords, _unset)
          ? this.useCoords
          : useCoords as bool?,
    );
  }
}
