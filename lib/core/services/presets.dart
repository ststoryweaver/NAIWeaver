import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../features/director_ref/models/director_reference.dart';
import '../../features/vibe_transfer/models/vibe_transfer.dart';
import '../../features/generation/models/nai_character.dart';

class GenerationPreset {
  final String name;
  final String prompt;
  final String negativePrompt;
  final double width;
  final double height;
  final double scale;
  final double steps;
  final String sampler;
  final bool smea;
  final bool smeaDyn;
  final bool decrisper;
  final List<NaiCharacter> characters;
  final List<NaiInteraction> interactions;
  final List<DirectorReference> directorReferences;
  final List<VibeTransfer> vibeTransfers;

  GenerationPreset({
    required this.name,
    required this.prompt,
    required this.negativePrompt,
    required this.width,
    required this.height,
    required this.scale,
    required this.steps,
    required this.sampler,
    required this.smea,
    required this.smeaDyn,
    required this.decrisper,
    this.characters = const [],
    this.interactions = const [],
    this.directorReferences = const [],
    this.vibeTransfers = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'prompt': prompt,
        'negativePrompt': negativePrompt,
        'width': width,
        'height': height,
        'scale': scale,
        'steps': steps,
        'sampler': sampler,
        'smea': smea,
        'smeaDyn': smeaDyn,
        'decrisper': decrisper,
        'characters': characters.map((c) => c.toJson()).toList(),
        'interactions': interactions.map((i) => i.toJson()).toList(),
        'directorReferences': directorReferences.map((r) => r.toJson()).toList(),
        'vibeTransfers': vibeTransfers.map((v) => v.toJson()).toList(),
      };

  factory GenerationPreset.fromJson(Map<String, dynamic> json) => GenerationPreset(
        name: json['name'],
        prompt: json['prompt'],
        negativePrompt: json['negativePrompt'],
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        scale: (json['scale'] as num).toDouble(),
        steps: (json['steps'] as num).toDouble(),
        sampler: json['sampler'],
        smea: json['smea'] ?? false,
        smeaDyn: json['smeaDyn'] ?? false,
        decrisper: json['decrisper'] ?? false,
        characters: (json['characters'] as List<dynamic>?)
                ?.map((c) => NaiCharacter.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
        interactions: (json['interactions'] as List<dynamic>?)
                ?.map((i) => NaiInteraction.fromJson(i as Map<String, dynamic>))
                .toList() ??
            const [],
        directorReferences: (json['directorReferences'] as List<dynamic>?)
                ?.map((r) => DirectorReference.fromJson(r as Map<String, dynamic>))
                .toList() ??
            const [],
        vibeTransfers: (json['vibeTransfers'] as List<dynamic>?)
                ?.map((v) => VibeTransfer.fromJson(v as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class PresetStorage {
  static Future<List<GenerationPreset>> loadPresets(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((json) => GenerationPreset.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error loading presets: $e");
      return [];
    }
  }

  static Future<void> savePresets(String filePath, List<GenerationPreset> presets) async {
    try {
      final file = File(filePath);
      final jsonList = presets.map((p) => p.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint("Error saving presets: $e");
    }
  }
}
