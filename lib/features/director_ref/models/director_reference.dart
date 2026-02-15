import 'dart:convert';
import 'dart:typed_data';

enum DirectorReferenceType {
  character,
  style,
  characterAndStyle,
}

extension DirectorReferenceTypeX on DirectorReferenceType {
  String get apiCaption {
    switch (this) {
      case DirectorReferenceType.character:
        return 'character';
      case DirectorReferenceType.style:
        return 'style';
      case DirectorReferenceType.characterAndStyle:
        return 'character&style';
    }
  }

  String get label {
    switch (this) {
      case DirectorReferenceType.character:
        return 'CHARACTER';
      case DirectorReferenceType.style:
        return 'STYLE';
      case DirectorReferenceType.characterAndStyle:
        return 'CHAR & STYLE';
    }
  }
}

class DirectorReference {
  final String id;
  final Uint8List originalImageBytes;
  final String processedBase64;
  final DirectorReferenceType type;
  final double strength;
  final double fidelity;

  DirectorReference({
    required this.id,
    required this.originalImageBytes,
    required this.processedBase64,
    this.type = DirectorReferenceType.character,
    this.strength = 0.6,
    this.fidelity = 0.5,
  });

  DirectorReference copyWith({
    DirectorReferenceType? type,
    double? strength,
    double? fidelity,
    String? processedBase64,
  }) {
    return DirectorReference(
      id: id,
      originalImageBytes: originalImageBytes,
      processedBase64: processedBase64 ?? this.processedBase64,
      type: type ?? this.type,
      strength: strength ?? this.strength,
      fidelity: fidelity ?? this.fidelity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalImageBytes': base64Encode(originalImageBytes),
        'type': type.name,
        'strength': strength,
        'fidelity': fidelity,
      };

  factory DirectorReference.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'character';
    final type = DirectorReferenceType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => DirectorReferenceType.character,
    );
    return DirectorReference(
      id: json['id'] as String? ?? 'ref_0',
      originalImageBytes: base64Decode(json['originalImageBytes'] as String),
      processedBase64: '', // Re-derived on load via ReferenceImageProcessor
      type: type,
      strength: (json['strength'] as num?)?.toDouble() ?? 0.6,
      fidelity: (json['fidelity'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

/// DTO: the 5 parallel lists ready for API injection.
class DirectorRefPayload {
  final List<String> images;
  final List<Map<String, dynamic>> descriptions;
  final List<double> strengths;
  final List<double> secondaryStrengths;
  final List<double> infoExtracted;

  DirectorRefPayload({
    required this.images,
    required this.descriptions,
    required this.strengths,
    required this.secondaryStrengths,
    required this.infoExtracted,
  });
}
