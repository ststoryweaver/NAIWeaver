import '../../../generation/models/nai_character.dart';

class BeatCharacterSlot {
  final NaiCoordinate position;
  /// The action tag, e.g., "source#hugging", "target#hugging", "mutual#holding hands"
  /// Can be null if no specific interaction is defined for this slot.
  final String? actionTag;
  
  final String positivePrompt;
  final String negativePrompt;

  BeatCharacterSlot({
    required this.position,
    this.actionTag,
    this.positivePrompt = "",
    this.negativePrompt = "",
  });

  factory BeatCharacterSlot.fromJson(Map<String, dynamic> json) => BeatCharacterSlot(
        position: NaiCoordinate.fromJson(json['position']),
        actionTag: json['actionTag'],
        positivePrompt: json['positivePrompt'] ?? "",
        negativePrompt: json['negativePrompt'] ?? "",
      );

  Map<String, dynamic> toJson() => {
        'position': position.toJson(),
        'actionTag': actionTag,
        'positivePrompt': positivePrompt,
        'negativePrompt': negativePrompt,
      };

  BeatCharacterSlot copyWith({
    NaiCoordinate? position,
    String? actionTag,
    String? positivePrompt,
    String? negativePrompt,
  }) {
    return BeatCharacterSlot(
      position: position ?? this.position,
      actionTag: actionTag ?? this.actionTag,
      positivePrompt: positivePrompt ?? this.positivePrompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
    );
  }
}

class CascadeBeat {
  final List<BeatCharacterSlot> characterSlots;
  final String environmentTags;
  
  // Per-beat generation settings
  final String sampler;
  final int steps;
  final double scale;
  final int width;
  final int height;
  final List<String> activeStyleNames;

  CascadeBeat({
    required this.characterSlots,
    required this.environmentTags,
    this.sampler = "k_euler_ancestral",
    this.steps = 28,
    this.scale = 6.0,
    this.width = 832,
    this.height = 1216,
    this.activeStyleNames = const [],
  });

  factory CascadeBeat.fromJson(Map<String, dynamic> json) => CascadeBeat(
        characterSlots: (json['characterSlots'] as List)
            .map((e) => BeatCharacterSlot.fromJson(e))
            .toList(),
        environmentTags: json['environmentTags'],
        sampler: json['sampler'] ?? "k_euler_ancestral",
        steps: json['steps'] ?? 28,
        scale: (json['scale'] as num?)?.toDouble() ?? 6.0,
        width: json['width'] ?? 832,
        height: json['height'] ?? 1216,
        activeStyleNames: (json['activeStyleNames'] as List?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'characterSlots': characterSlots.map((e) => e.toJson()).toList(),
        'environmentTags': environmentTags,
        'sampler': sampler,
        'steps': steps,
        'scale': scale,
        'width': width,
        'height': height,
        'activeStyleNames': activeStyleNames,
      };

  CascadeBeat copyWith({
    List<BeatCharacterSlot>? characterSlots,
    String? environmentTags,
    String? sampler,
    int? steps,
    double? scale,
    int? width,
    int? height,
    List<String>? activeStyleNames,
  }) {
    return CascadeBeat(
      characterSlots: characterSlots ?? this.characterSlots,
      environmentTags: environmentTags ?? this.environmentTags,
      sampler: sampler ?? this.sampler,
      steps: steps ?? this.steps,
      scale: scale ?? this.scale,
      width: width ?? this.width,
      height: height ?? this.height,
      activeStyleNames: activeStyleNames ?? this.activeStyleNames,
    );
  }
}
