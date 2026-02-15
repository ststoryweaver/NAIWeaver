import 'cascade_beat.dart';

class PromptCascade {
  final String name;
  final int characterCount;
  final List<CascadeBeat> beats;
  final Map<String, dynamic> metadata;
  final bool useCoords;

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
        beats: (json['beats'] as List)
            .map((e) => CascadeBeat.fromJson(e))
            .toList(),
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
