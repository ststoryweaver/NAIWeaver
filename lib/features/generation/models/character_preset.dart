class CharacterPreset {
  final String id;
  final String name;
  final String prompt;
  final String uc;

  CharacterPreset({
    required this.id,
    required this.name,
    required this.prompt,
    required this.uc,
  });

  factory CharacterPreset.fromJson(Map<String, dynamic> json) =>
      CharacterPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        prompt: json['prompt'] as String? ?? '',
        uc: json['uc'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'prompt': prompt,
        'uc': uc,
      };
}
