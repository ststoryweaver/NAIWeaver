import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/nai_character.dart';
import '../../director_ref/models/director_reference.dart';
import '../../vibe_transfer/models/vibe_transfer.dart';

/// Data object for session snapshot serialization.
class SessionSnapshot {
  final String prompt;
  final String negativePrompt;
  final String seed;
  final double width;
  final double height;
  final double scale;
  final double steps;
  final String sampler;
  final bool smea;
  final bool smeaDyn;
  final bool decrisper;
  final bool randomizeSeed;
  final bool autoPositioning;
  final List<String> activeStyleNames;
  final bool isStyleEnabled;
  final bool furryMode;
  final List<NaiCharacter> characters;
  final List<NaiInteraction> interactions;
  final List<DirectorReference> directorReferences;
  final List<VibeTransfer> vibeTransfers;

  SessionSnapshot({
    required this.prompt,
    required this.negativePrompt,
    required this.seed,
    required this.width,
    required this.height,
    required this.scale,
    required this.steps,
    required this.sampler,
    required this.smea,
    required this.smeaDyn,
    required this.decrisper,
    required this.randomizeSeed,
    required this.autoPositioning,
    required this.activeStyleNames,
    required this.isStyleEnabled,
    required this.furryMode,
    required this.characters,
    required this.interactions,
    required this.directorReferences,
    required this.vibeTransfers,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'negative_prompt': negativePrompt,
        'seed': seed,
        'width': width,
        'height': height,
        'scale': scale,
        'steps': steps,
        'sampler': sampler,
        'smea': smea,
        'smea_dyn': smeaDyn,
        'decrisper': decrisper,
        'randomize_seed': randomizeSeed,
        'auto_positioning': autoPositioning,
        'active_style_names': activeStyleNames,
        'is_style_enabled': isStyleEnabled,
        'furry_mode': furryMode,
        'characters': characters.map((c) => c.toJson()).toList(),
        'interactions': interactions.map((i) => i.toJson()).toList(),
        'director_references':
            directorReferences.map((r) => r.toJson()).toList(),
        'vibe_transfers': vibeTransfers.map((v) => v.toJson()).toList(),
      };

  factory SessionSnapshot.fromJson(Map<String, dynamic> json) {
    final characters = (json['characters'] as List<dynamic>?)
            ?.map((c) => NaiCharacter.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    final interactions = (json['interactions'] as List<dynamic>?)
            ?.map((i) => NaiInteraction.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];
    final directorReferences = (json['director_references'] as List<dynamic>?)
            ?.map(
                (r) => DirectorReference.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];
    final vibeTransfers = (json['vibe_transfers'] as List<dynamic>?)
            ?.map((v) => VibeTransfer.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];

    return SessionSnapshot(
      prompt: json['prompt'] as String? ?? '',
      negativePrompt: json['negative_prompt'] as String? ?? '',
      seed: json['seed'] as String? ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 832,
      height: (json['height'] as num?)?.toDouble() ?? 1216,
      scale: (json['scale'] as num?)?.toDouble() ?? 5.0,
      steps: (json['steps'] as num?)?.toDouble() ?? 28,
      sampler: json['sampler'] as String? ?? 'k_euler_ancestral',
      smea: json['smea'] as bool? ?? false,
      smeaDyn: json['smea_dyn'] as bool? ?? false,
      decrisper: json['decrisper'] as bool? ?? false,
      randomizeSeed: json['randomize_seed'] as bool? ?? true,
      autoPositioning: json['auto_positioning'] as bool? ?? false,
      activeStyleNames: (json['active_style_names'] as List<dynamic>?)
              ?.cast<String>()
              .toList() ??
          [],
      isStyleEnabled: json['is_style_enabled'] as bool? ?? true,
      furryMode: json['furry_mode'] as bool? ?? false,
      characters: characters,
      interactions: interactions,
      directorReferences: directorReferences,
      vibeTransfers: vibeTransfers,
    );
  }
}

/// Handles saving, restoring, and deleting session snapshot files.
class SessionSnapshotService {
  final String sessionFilePath;

  SessionSnapshotService({required this.sessionFilePath});

  Future<void> save(SessionSnapshot snapshot) async {
    try {
      await File(sessionFilePath).writeAsString(jsonEncode(snapshot.toJson()));
    } catch (e) {
      debugPrint('Session save error: $e');
    }
  }

  Future<SessionSnapshot?> restore() async {
    try {
      final file = File(sessionFilePath);
      if (!await file.exists()) return null;

      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return SessionSnapshot.fromJson(json);
    } catch (e) {
      debugPrint('Session restore error: $e');
      return null;
    }
  }

  Future<void> delete() async {
    try {
      final file = File(sessionFilePath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Session delete error: $e');
    }
  }
}
