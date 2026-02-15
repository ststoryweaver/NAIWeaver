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
  final int sourceCharacterIndex;
  final int targetCharacterIndex;
  final String actionName;
  final InteractionType type;

  NaiInteraction({
    required this.sourceCharacterIndex,
    required this.targetCharacterIndex,
    required this.actionName,
    required this.type,
  });

  factory NaiInteraction.fromJson(Map<String, dynamic> json) => NaiInteraction(
        sourceCharacterIndex: json['sourceCharacterIndex'],
        targetCharacterIndex: json['targetCharacterIndex'],
        actionName: json['actionName'],
        type: InteractionType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => InteractionType.sourceTarget,
        ),
      );

  Map<String, dynamic> toJson() => {
        'sourceCharacterIndex': sourceCharacterIndex,
        'targetCharacterIndex': targetCharacterIndex,
        'actionName': actionName,
        'type': type.toString(),
      };

  NaiInteraction copyWith({
    int? sourceCharacterIndex,
    int? targetCharacterIndex,
    String? actionName,
    InteractionType? type,
  }) {
    return NaiInteraction(
      sourceCharacterIndex: sourceCharacterIndex ?? this.sourceCharacterIndex,
      targetCharacterIndex: targetCharacterIndex ?? this.targetCharacterIndex,
      actionName: actionName ?? this.actionName,
      type: type ?? this.type,
    );
  }
}

class NaiCharacter {
  final String prompt;
  final String uc;
  final NaiCoordinate center;

  NaiCharacter({
    required this.prompt,
    required this.uc,
    required this.center,
  });

  factory NaiCharacter.fromJson(Map<String, dynamic> json) => NaiCharacter(
        prompt: json['prompt'],
        uc: json['uc'],
        center: NaiCoordinate.fromJson(json['center']),
      );

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'uc': uc,
        'center': center.toJson(),
      };

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
