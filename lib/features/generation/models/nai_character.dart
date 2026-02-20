class NaiCoordinate {
  final double x;
  final double y;

  NaiCoordinate({required this.x, required this.y});

  factory NaiCoordinate.fromJson(Map<String, dynamic> json) => NaiCoordinate(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
      };
}

enum InteractionType {
  sourceTarget,
  mutual,
}

class NaiInteraction {
  final List<int> sourceCharacterIndices;
  final List<int> targetCharacterIndices;
  final String actionName;
  final InteractionType type;

  NaiInteraction({
    required this.sourceCharacterIndices,
    required this.targetCharacterIndices,
    required this.actionName,
    required this.type,
  });

  /// Deprecated: use [sourceCharacterIndices] instead.
  @Deprecated('Use sourceCharacterIndices instead')
  int get sourceCharacterIndex => sourceCharacterIndices.first;

  /// Deprecated: use [targetCharacterIndices] instead.
  @Deprecated('Use targetCharacterIndices instead')
  int get targetCharacterIndex =>
      targetCharacterIndices.isNotEmpty ? targetCharacterIndices.first : sourceCharacterIndices.last;

  factory NaiInteraction.fromJson(Map<String, dynamic> json) {
    // Backward-compatible: detect old single-int format vs new list format
    final List<int> sources;
    final List<int> targets;
    if (json.containsKey('sourceCharacterIndices')) {
      sources = (json['sourceCharacterIndices'] as List).cast<int>();
      targets = (json['targetCharacterIndices'] as List).cast<int>();
    } else {
      sources = [json['sourceCharacterIndex'] as int];
      targets = [json['targetCharacterIndex'] as int];
    }
    return NaiInteraction(
      sourceCharacterIndices: sources,
      targetCharacterIndices: targets,
      actionName: json['actionName'],
      type: InteractionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => InteractionType.sourceTarget,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceCharacterIndices': sourceCharacterIndices,
        'targetCharacterIndices': targetCharacterIndices,
        'actionName': actionName,
        'type': type.toString(),
      };

  NaiInteraction copyWith({
    List<int>? sourceCharacterIndices,
    List<int>? targetCharacterIndices,
    String? actionName,
    InteractionType? type,
  }) {
    return NaiInteraction(
      sourceCharacterIndices: sourceCharacterIndices ?? List.of(this.sourceCharacterIndices),
      targetCharacterIndices: targetCharacterIndices ?? List.of(this.targetCharacterIndices),
      actionName: actionName ?? this.actionName,
      type: type ?? this.type,
    );
  }
}

class NaiCharacter {
  final String name;
  final String prompt;
  final String uc;
  final NaiCoordinate center;

  NaiCharacter({
    this.name = '',
    required this.prompt,
    required this.uc,
    required this.center,
  });

  factory NaiCharacter.fromJson(Map<String, dynamic> json) => NaiCharacter(
        name: json['name'] as String? ?? '',
        prompt: json['prompt'],
        uc: json['uc'],
        center: NaiCoordinate.fromJson(json['center']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'prompt': prompt,
        'uc': uc,
        'center': center.toJson(),
      };

  NaiCharacter copyWith({
    String? name,
    String? prompt,
    String? uc,
    NaiCoordinate? center,
  }) {
    return NaiCharacter(
      name: name ?? this.name,
      prompt: prompt ?? this.prompt,
      uc: uc ?? this.uc,
      center: center ?? this.center,
    );
  }

  Map<String, dynamic> toCharacterPrompt() {
    return {
      'prompt': prompt,
      'center': center.toJson(),
    };
  }

  Map<String, dynamic> toV4Prompt() {
    return {
      'char_caption': prompt,
      'centers': [center.toJson()],
    };
  }

  Map<String, dynamic> toV4NegativePrompt() {
    return {
      'char_caption': uc,
      'centers': [center.toJson()],
    };
  }
}
