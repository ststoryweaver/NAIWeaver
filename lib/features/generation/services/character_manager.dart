import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/services/preferences_service.dart';
import '../models/nai_character.dart';
import '../models/character_preset.dart';

/// Manages character/interaction CRUD and character presets.
class CharacterManager {
  final PreferencesService _prefs;

  CharacterManager({required PreferencesService prefs}) : _prefs = prefs;

  /// Add a new character. Returns updated characters list, or null if at capacity.
  List<NaiCharacter>? addCharacter(List<NaiCharacter> current,
      {String name = ''}) {
    if (current.length >= 6) return null;
    return List<NaiCharacter>.from(current)
      ..add(NaiCharacter(
        name: name,
        prompt: "",
        uc: "",
        center: NaiCoordinate(x: 0.5, y: 0.5),
      ));
  }

  /// Update a character at [index]. Returns updated list, or null if index invalid.
  List<NaiCharacter>? updateCharacter(
      List<NaiCharacter> current, int index, NaiCharacter character) {
    if (index < 0 || index >= current.length) return null;
    final updated = List<NaiCharacter>.from(current);
    updated[index] = character;
    return updated;
  }

  /// Remove character at [index]. Returns updated characters and interactions,
  /// or null if index invalid.
  ({List<NaiCharacter> characters, List<NaiInteraction> interactions})?
      removeCharacter(
    List<NaiCharacter> characters,
    List<NaiInteraction> interactions,
    int index,
  ) {
    if (index < 0 || index >= characters.length) return null;

    // Update characters
    final updatedChars = List<NaiCharacter>.from(characters)..removeAt(index);

    // Cleanup interactions: remove the index from lists, decrement higher indices
    final updatedInteractions = interactions
        .map((i) {
          var sources =
              i.sourceCharacterIndices.where((s) => s != index).toList();
          var targets =
              i.targetCharacterIndices.where((t) => t != index).toList();
          sources = sources.map((s) => s > index ? s - 1 : s).toList();
          targets = targets.map((t) => t > index ? t - 1 : t).toList();
          return i.copyWith(
              sourceCharacterIndices: sources,
              targetCharacterIndices: targets);
        })
        .where((i) {
          if (i.type == InteractionType.mutual) {
            return i.sourceCharacterIndices.isNotEmpty;
          }
          return i.sourceCharacterIndices.isNotEmpty &&
              i.targetCharacterIndices.isNotEmpty;
        })
        .toList();

    return (characters: updatedChars, interactions: updatedInteractions);
  }

  /// Update or add an interaction. Returns updated interactions list.
  List<NaiInteraction> updateInteraction(
    List<NaiInteraction> current,
    NaiInteraction interaction, {
    NaiInteraction? replacing,
  }) {
    final updated = List<NaiInteraction>.from(current);

    // Find existing by identity match (same action + overlapping participants) or explicit replacing reference
    final existingIndex = replacing != null
        ? updated.indexWhere((i) =>
            i.actionName == replacing.actionName && i.type == replacing.type)
        : updated.indexWhere((i) => i.actionName == interaction.actionName);

    if (existingIndex >= 0) {
      if (interaction.actionName.isEmpty) {
        updated.removeAt(existingIndex);
      } else {
        updated[existingIndex] = interaction;
      }
    } else if (interaction.actionName.isNotEmpty) {
      updated.add(interaction);
    }

    return updated;
  }

  /// Remove an interaction. Returns updated interactions list.
  List<NaiInteraction> removeInteraction(
      List<NaiInteraction> current, NaiInteraction interaction) {
    final updated = List<NaiInteraction>.from(current);
    updated.removeWhere(
        (i) => i.actionName == interaction.actionName && i.type == interaction.type);
    return updated;
  }

  /// Apply a character preset to a character at [charIndex].
  /// Returns updated character list, or null if index invalid.
  List<NaiCharacter>? applyCharacterPreset(
      List<NaiCharacter> current, int charIndex, CharacterPreset preset) {
    if (charIndex < 0 || charIndex >= current.length) return null;
    final updated = List<NaiCharacter>.from(current);
    updated[charIndex] = updated[charIndex].copyWith(
      name: preset.name,
      prompt: preset.prompt,
      uc: preset.uc,
    );
    return updated;
  }

  // — Character Presets persistence —

  List<CharacterPreset> loadPresets() {
    final raw = _prefs.characterPresets;
    if (raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CharacterPreset.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CharacterManager.loadPresets: $e');
      return [];
    }
  }

  Future<void> persistPresets(List<CharacterPreset> presets) async {
    final json =
        jsonEncode(presets.map((p) => p.toJson()).toList());
    await _prefs.setCharacterPresets(json);
  }
}
