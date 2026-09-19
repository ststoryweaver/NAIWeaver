import 'cascade_beat.dart';

class PromptCascade {
  /// Default upper bound on slots per beat / cast size, matching the
  /// create-cascade slot picker (0–6) and V4.5's character limit. The director
  /// raises it to the active model's limit (32 on V5) when adding characters.
  static const int maxCharacterSlots = 6;

  final String name;
  final int characterCount;
  final List<CascadeBeat> beats;
  final Map<String, dynamic> metadata;
  final bool useCoords;

  /// Manual placement for [beat]: the beat's own override, else this cascade.
  bool effectiveUseCoords(CascadeBeat beat) => beat.useCoords ?? useCoords;

  PromptCascade({
    required this.name,
    required this.characterCount,
    required this.beats,
    this.metadata = const {},
    this.useCoords = true,
  });

  factory PromptCascade.fromJson(Map<String, dynamic> json) => PromptCascade(
    name: json['name'],
    characterCount: json['characterCount'],
    beats: [
      for (final (i, beat) in (json['beats'] as List).indexed)
        CascadeBeat.fromJson(beat, fallbackId: 'legacy_$i'),
    ],
    metadata: json['metadata'] ?? {},
    useCoords: json['useCoords'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'characterCount': characterCount,
    'beats': beats.map((e) => e.toJson()).toList(),
    'metadata': metadata,
    'useCoords': useCoords,
  };

  PromptCascade copyWith({
    String? name,
    int? characterCount,
    List<CascadeBeat>? beats,
    Map<String, dynamic>? metadata,
    bool? useCoords,
  }) {
    return PromptCascade(
      name: name ?? this.name,
      characterCount: characterCount ?? this.characterCount,
      beats: beats ?? this.beats,
      metadata: metadata ?? this.metadata,
      useCoords: useCoords ?? this.useCoords,
    );
  }
}
