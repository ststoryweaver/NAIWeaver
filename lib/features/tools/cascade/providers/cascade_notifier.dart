import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prompt_cascade.dart';
import '../models/cascade_beat.dart';
import '../../../generation/models/nai_character.dart';

class CascadeState {
  final List<PromptCascade> savedCascades;
  final PromptCascade? activeCascade;
  final int? selectedBeatIndex;
  final bool isLoading;

  // Casting & Playback
  final List<String> characterAppearances;
  final String globalSceneTags;
  final String globalInjection;
  final Map<int, Uint8List?> beatPreviews;

  /// Gallery filename for each beat that has been saved this session, so the
  /// album picker can check membership of the *currently viewed* beat instead
  /// of whatever was last generated.
  final Map<int, String> beatSavedBasenames;

  /// Generation metadata (prompt, seed, settings) for each beat preview, so
  /// saving a beat after switching back to it embeds *its* record rather than
  /// the last generated beat's. Cast-time state, like [beatPreviews].
  final Map<int, Map<String, dynamic>> beatMetadata;

  /// Free-text narration captions per beat index. Cast-time state for *this*
  /// run (like [characterAppearances]) — narration shown over the beat preview,
  /// never part of the saved cascade and never baked into [beatPreviews] bytes.
  final Map<int, String> beatCaptions;

  /// Whether narration captions are rendered over beat previews. User toggle.
  final bool captionsVisible;

  CascadeState({
    this.savedCascades = const [],
    this.activeCascade,
    this.selectedBeatIndex,
    this.isLoading = false,
    this.characterAppearances = const [],
    this.globalSceneTags = "",
    this.globalInjection = "",
    this.beatPreviews = const {},
    this.beatSavedBasenames = const {},
    this.beatMetadata = const {},
    this.beatCaptions = const {},
    this.captionsVisible = true,
  });

  CascadeState copyWith({
    List<PromptCascade>? savedCascades,
    PromptCascade? activeCascade,
    bool clearActiveCascade = false,
    int? selectedBeatIndex,
    bool clearSelectedBeatIndex = false,
    bool? isLoading,
    List<String>? characterAppearances,
    String? globalSceneTags,
    String? globalInjection,
    Map<int, Uint8List?>? beatPreviews,
    Map<int, String>? beatSavedBasenames,
    Map<int, Map<String, dynamic>>? beatMetadata,
    Map<int, String>? beatCaptions,
    bool? captionsVisible,
  }) {
    return CascadeState(
      savedCascades: savedCascades ?? this.savedCascades,
      activeCascade: clearActiveCascade
          ? null
          : (activeCascade ?? this.activeCascade),
      selectedBeatIndex: clearSelectedBeatIndex
          ? null
          : (selectedBeatIndex ?? this.selectedBeatIndex),
      isLoading: isLoading ?? this.isLoading,
      characterAppearances: characterAppearances ?? this.characterAppearances,
      globalSceneTags: globalSceneTags ?? this.globalSceneTags,
      globalInjection: globalInjection ?? this.globalInjection,
      beatPreviews: beatPreviews ?? this.beatPreviews,
      beatSavedBasenames: beatSavedBasenames ?? this.beatSavedBasenames,
      beatMetadata: beatMetadata ?? this.beatMetadata,
      beatCaptions: beatCaptions ?? this.beatCaptions,
      captionsVisible: captionsVisible ?? this.captionsVisible,
    );
  }
}

class CascadeNotifier extends ChangeNotifier {
  static const String _storageKey = 'saved_prompt_cascades';

  CascadeState _state = CascadeState();
  CascadeState get state => _state;

  String? _savedSnapshot;

  bool get hasUnsavedChanges {
    if (_state.activeCascade == null) return false;
    return json.encode(_state.activeCascade!.toJson()) != _savedSnapshot;
  }

  CascadeNotifier() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        final cascades = decoded.map((e) => PromptCascade.fromJson(e)).toList();
        _state = _state.copyWith(savedCascades: cascades, isLoading: false);
      } else {
        _state = _state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error loading cascades: $e');
      _state = _state.copyWith(isLoading: false);
    }
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(
        _state.savedCascades.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving cascades: $e');
    }
  }

  void setActiveCascade(PromptCascade? cascade) {
    _savedSnapshot = cascade != null ? json.encode(cascade.toJson()) : null;
    _state = _state.copyWith(
      activeCascade: cascade,
      clearActiveCascade: cascade == null,
      selectedBeatIndex: cascade != null && cascade.beats.isNotEmpty ? 0 : null,
      clearSelectedBeatIndex: cascade == null,
      characterAppearances: cascade != null
          ? List.generate(cascade.characterCount, (_) => "")
          : [],
      globalSceneTags: "",
      globalInjection: "",
      beatPreviews: {},
      beatSavedBasenames: {},
      beatMetadata: {},
      beatCaptions: {},
    );
    notifyListeners();
  }

  void exitCascadeMode() {
    _state = _state.copyWith(
      clearActiveCascade: true,
      clearSelectedBeatIndex: true,
      characterAppearances: [],
      globalSceneTags: "",
      globalInjection: "",
      beatPreviews: {},
      beatSavedBasenames: {},
      beatMetadata: {},
      beatCaptions: {},
    );
    notifyListeners();
  }

  void updateAppearance(int index, String appearance) {
    final updated = List<String>.from(_state.characterAppearances);
    if (index >= 0 && index < updated.length) {
      updated[index] = appearance;
      _state = _state.copyWith(characterAppearances: updated);
      notifyListeners();
    }
  }

  void updateGlobalSceneTags(String val) {
    _state = _state.copyWith(globalSceneTags: val);
    notifyListeners();
  }

  void updateGlobalInjection(String val) {
    _state = _state.copyWith(globalInjection: val);
    notifyListeners();
  }

  /// Records a freshly generated (or cleared) preview for [index]. Pass the
  /// generation [metadata] so a later save of this beat embeds the right
  /// record; a missing/null [metadata] drops any stale entry.
  void setBeatPreview(
    int index,
    Uint8List? bytes, {
    Map<String, dynamic>? metadata,
  }) {
    final updated = Map<int, Uint8List?>.from(_state.beatPreviews);
    updated[index] = bytes;
    final meta = Map<int, Map<String, dynamic>>.from(_state.beatMetadata);
    if (metadata == null) {
      meta.remove(index);
    } else {
      meta[index] = metadata;
    }
    _state = _state.copyWith(beatPreviews: updated, beatMetadata: meta);
    notifyListeners();
  }

  /// Binds [basename] to beat [index]; null means the beat's current image
  /// is not on disk (e.g. it was just regenerated with auto-save off), so any
  /// stale filename from an earlier render is forgotten.
  void setBeatSavedBasename(int index, String? basename) {
    final updated = Map<int, String>.from(_state.beatSavedBasenames);
    if (basename == null) {
      updated.remove(index);
    } else {
      updated[index] = basename;
    }
    _state = _state.copyWith(beatSavedBasenames: updated);
    notifyListeners();
  }

  /// Bind [basename] to whichever beat currently holds [image] in memory.
  void recordBasenameForImage(Uint8List? image, String basename) {
    if (image == null) return;
    for (final entry in _state.beatPreviews.entries) {
      if (identical(entry.value, image)) {
        setBeatSavedBasename(entry.key, basename);
        return;
      }
    }
  }

  void setBeatCaption(int index, String text) {
    final updated = Map<int, String>.from(_state.beatCaptions);
    if (text.isEmpty) {
      updated.remove(index);
    } else {
      updated[index] = text;
    }
    _state = _state.copyWith(beatCaptions: updated);
    notifyListeners();
  }

  void toggleCaptionsVisible() {
    _state = _state.copyWith(captionsVisible: !_state.captionsVisible);
    notifyListeners();
  }

  void selectBeat(int index) {
    if (_state.activeCascade == null ||
        index < 0 ||
        index >= _state.activeCascade!.beats.length) {
      return;
    }
    _state = _state.copyWith(selectedBeatIndex: index);
    notifyListeners();
  }

  void createNewCascade(
    String name,
    int characterCount, {
    bool useCoords = true,
  }) {
    final newCascade = PromptCascade(
      name: name,
      characterCount: characterCount,
      useCoords: useCoords,
      beats: [
        // Start with one empty beat
        CascadeBeat(
          characterSlots: List.generate(characterCount, _emptySlot),
          environmentTags: "",
          useCoords: useCoords,
        ),
      ],
    );
    _savedSnapshot = null; // Never saved yet → always dirty
    // Seed cast-time state the same way setActiveCascade does. Without this the
    // appearance list stays empty (0) while each beat has 1+ character slots, so
    // CascadeStitchingService.render throws "Not enough character appearances"
    // and beat generation silently no-ops.
    _state = _state.copyWith(
      activeCascade: newCascade,
      selectedBeatIndex: 0,
      characterAppearances: List.generate(characterCount, (_) => ""),
      globalSceneTags: "",
      globalInjection: "",
      beatPreviews: {},
      beatSavedBasenames: {},
      beatMetadata: {},
      beatCaptions: {},
    );
    notifyListeners();
  }

  void saveActiveToLibrary() {
    if (_state.activeCascade == null) return;

    final existingIndex = _state.savedCascades.indexWhere(
      (c) => c.name == _state.activeCascade!.name,
    );
    List<PromptCascade> updatedList;
    if (existingIndex >= 0) {
      updatedList = List<PromptCascade>.from(_state.savedCascades)
        ..[existingIndex] = _state.activeCascade!;
    } else {
      updatedList = List<PromptCascade>.from(_state.savedCascades)
        ..add(_state.activeCascade!);
    }

    _savedSnapshot = json.encode(_state.activeCascade!.toJson());
    _state = _state.copyWith(savedCascades: updatedList);
    _saveToStorage();
    notifyListeners();
  }

  void deleteCascade(String name) {
    final updatedList = _state.savedCascades
        .where((c) => c.name != name)
        .toList();
    _state = _state.copyWith(savedCascades: updatedList);
    if (_state.activeCascade?.name == name) {
      _state = _state.copyWith(activeCascade: null, selectedBeatIndex: null);
    }
    _saveToStorage();
    notifyListeners();
  }

  void addBeat() {
    if (_state.activeCascade == null) return;

    final last = _state.activeCascade!.beats.isNotEmpty
        ? _state.activeCascade!.beats.last
        : null;
    // A new beat opens with the same cast as the previous one (fresh slots,
    // same characters) so a story keeps its people unless the user says so.
    final castIndices = last != null
        ? last.characterSlots.map((s) => s.castIndex).toList()
        : List.generate(_state.activeCascade!.characterCount, (i) => i);
    final newBeat = CascadeBeat(
      characterSlots: castIndices.map(_emptySlot).toList(),
      environmentTags: last?.environmentTags ?? "",
      width: last?.width ?? 832,
      height: last?.height ?? 1216,
      useCoords: last?.useCoords ?? _state.activeCascade!.useCoords,
    );

    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats)
      ..add(newBeat);
    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
      selectedBeatIndex: updatedBeats.length - 1,
    );
    notifyListeners();
  }

  void cloneBeat(int index) {
    if (_state.activeCascade == null ||
        index < 0 ||
        index >= _state.activeCascade!.beats.length) {
      return;
    }

    final sourceBeat = _state.activeCascade!.beats[index];
    final clonedBeat = CascadeBeat(
      characterSlots: sourceBeat.characterSlots
          .map(
            (s) => BeatCharacterSlot(
              position: s.position,
              castIndex: s.castIndex,
              actionTags: List.of(s.actionTags),
              positivePrompt: s.positivePrompt,
              negativePrompt: s.negativePrompt,
            ),
          )
          .toList(),
      sceneTags: sourceBeat.sceneTags,
      environmentTags: sourceBeat.environmentTags,
      sampler: sourceBeat.sampler,
      steps: sourceBeat.steps,
      scale: sourceBeat.scale,
      width: sourceBeat.width,
      height: sourceBeat.height,
      activeStyleNames: List.of(sourceBeat.activeStyleNames),
      useCoords: sourceBeat.useCoords,
    );

    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats)
      ..insert(index + 1, clonedBeat);
    // The cloned beat starts un-generated and un-captioned. Shift every cast-time
    // map entry at or after the insertion point up by one so previews/captions
    // stay glued to their beats.
    final insertAt = index + 1;
    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
      selectedBeatIndex: insertAt,
      beatPreviews: _shiftForInsert(_state.beatPreviews, insertAt),
      beatSavedBasenames: _shiftForInsert(_state.beatSavedBasenames, insertAt),
      beatMetadata: _shiftForInsert(_state.beatMetadata, insertAt),
      beatCaptions: _shiftForInsert(_state.beatCaptions, insertAt),
    );
    notifyListeners();
  }

  void removeBeat(int index) {
    if (_state.activeCascade == null ||
        _state.activeCascade!.beats.length <= 1) {
      return;
    }

    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats)
      ..removeAt(index);
    int? newSelectedIndex = _state.selectedBeatIndex;
    if (newSelectedIndex != null) {
      if (newSelectedIndex >= updatedBeats.length) {
        newSelectedIndex = updatedBeats.length - 1;
      }
    }

    // Drop the removed beat's preview/caption and shift everything after it down
    // by one so the remaining beats keep their own cast-time state.
    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
      selectedBeatIndex: newSelectedIndex,
      beatPreviews: _shiftForRemoval(_state.beatPreviews, index),
      beatSavedBasenames: _shiftForRemoval(_state.beatSavedBasenames, index),
      beatMetadata: _shiftForRemoval(_state.beatMetadata, index),
      beatCaptions: _shiftForRemoval(_state.beatCaptions, index),
    );
    notifyListeners();
  }

  void reorderBeats(int oldIndex, int newIndex) {
    if (_state.activeCascade == null) return;

    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updatedBeats.removeAt(oldIndex);
    updatedBeats.insert(newIndex, item);

    // Apply the same removeAt/insert permutation to the cast-time maps so each
    // beat's preview/caption travels with it.
    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
      selectedBeatIndex: newIndex,
      beatPreviews: _shiftForReorder(_state.beatPreviews, oldIndex, newIndex),
      beatSavedBasenames: _shiftForReorder(
        _state.beatSavedBasenames,
        oldIndex,
        newIndex,
      ),
      beatMetadata: _shiftForReorder(_state.beatMetadata, oldIndex, newIndex),
      beatCaptions: _shiftForReorder(_state.beatCaptions, oldIndex, newIndex),
    );
    notifyListeners();
  }

  /// Re-key an index-keyed cast-time map after a beat at [removed] is deleted:
  /// keys below [removed] stay put, the key at [removed] is dropped, keys above
  /// shift down by one.
  static Map<int, T> _shiftForRemoval<T>(Map<int, T> map, int removed) {
    final out = <int, T>{};
    map.forEach((k, v) {
      if (k < removed) {
        out[k] = v;
      } else if (k > removed) {
        out[k - 1] = v;
      }
    });
    return out;
  }

  /// Re-key an index-keyed cast-time map after a new beat is inserted at
  /// [insertAt]: keys below stay put, keys at or above shift up by one (leaving
  /// [insertAt] empty for the new beat).
  static Map<int, T> _shiftForInsert<T>(Map<int, T> map, int insertAt) {
    final out = <int, T>{};
    map.forEach((k, v) {
      out[k >= insertAt ? k + 1 : k] = v;
    });
    return out;
  }

  /// Re-key an index-keyed cast-time map under the same removeAt(oldIndex) +
  /// insert(newIndex) permutation applied to the beats list, so each beat's
  /// preview/caption follows it to its new position.
  static Map<int, T> _shiftForReorder<T>(
    Map<int, T> map,
    int oldIndex,
    int newIndex,
  ) {
    final out = <int, T>{};
    map.forEach((k, v) {
      int nk;
      if (k == oldIndex) {
        nk = newIndex;
      } else {
        // First account for the removeAt(oldIndex)...
        var shifted = k > oldIndex ? k - 1 : k;
        // ...then the insert(newIndex).
        if (shifted >= newIndex) shifted += 1;
        nk = shifted;
      }
      out[nk] = v;
    });
    return out;
  }

  /// Copies [sceneTags] onto every beat in the active cascade. Powers the
  /// "apply to all beats" action — the fixed-shot / changing-action workflow.
  void applySceneToAllBeats(String sceneTags) {
    if (_state.activeCascade == null) return;
    final updatedBeats = _state.activeCascade!.beats
        .map((b) => b.copyWith(sceneTags: sceneTags))
        .toList();
    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
    );
    notifyListeners();
  }

  void updateActiveBeat(CascadeBeat updatedBeat) {
    if (_state.activeCascade == null || _state.selectedBeatIndex == null) {
      return;
    }

    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats);
    updatedBeats[_state.selectedBeatIndex!] = updatedBeat;

    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
    );
    notifyListeners();
  }

  static BeatCharacterSlot _emptySlot(int castIndex) => BeatCharacterSlot(
    position: NaiCoordinate(x: 0.5, y: 0.5),
    castIndex: castIndex,
  );

  /// Keeps [PromptCascade.characterCount] and cast-time appearances in sync
  /// with the cast members actually referenced by some beat. Members no beat
  /// uses any more are dropped and the survivors renumbered contiguously, with
  /// each appearance following its character.
  void _syncCastRoster(PromptCascade cascade) {
    final used = <int>{
      for (final b in cascade.beats)
        for (final s in b.characterSlots) s.castIndex,
    }.toList()..sort();
    final remap = {for (final (i, old) in used.indexed) old: i};

    final beats = cascade.beats
        .map(
          (b) => b.copyWith(
            characterSlots: [
              for (final s in b.characterSlots)
                s.castIndex == remap[s.castIndex]
                    ? s
                    : s.copyWith(castIndex: remap[s.castIndex]),
            ],
          ),
        )
        .toList();

    final old = _state.characterAppearances;
    final appearances = [for (final i in used) i < old.length ? old[i] : ''];

    _state = _state.copyWith(
      activeCascade: cascade.copyWith(
        beats: beats,
        characterCount: used.length,
      ),
      characterAppearances: appearances,
    );
  }

  /// Cast members not yet on the selected beat, in cast order.
  List<int> castMembersMissingFromActiveBeat() {
    if (_state.activeCascade == null || _state.selectedBeatIndex == null) {
      return const [];
    }
    final beat = _state.activeCascade!.beats[_state.selectedBeatIndex!];
    final present = beat.characterSlots.map((s) => s.castIndex).toSet();
    return [
      for (int i = 0; i < _state.activeCascade!.characterCount; i++)
        if (!present.contains(i)) i,
    ];
  }

  /// Adds a slot to the selected beat. [castIndex] picks an existing cast
  /// member who is not yet on the beat; omit it to add a brand-new character
  /// to the cast. Both the beat's slot count and the cast size are capped at
  /// [maxSlots], which callers set from the active model's character limit
  /// (6 on V4.5, 32 on V5); the default is the V4.5 figure.
  void addCharacterToActiveBeat({
    int? castIndex,
    int maxSlots = PromptCascade.maxCharacterSlots,
  }) {
    if (_state.activeCascade == null || _state.selectedBeatIndex == null) {
      return;
    }
    final cascade = _state.activeCascade!;
    final beat = cascade.beats[_state.selectedBeatIndex!];
    if (beat.characterSlots.length >= maxSlots) return;

    final int who;
    if (castIndex != null) {
      if (castIndex < 0 || castIndex >= cascade.characterCount) return;
      if (beat.characterSlots.any((s) => s.castIndex == castIndex)) return;
      who = castIndex;
    } else {
      if (cascade.characterCount >= maxSlots) return;
      who = cascade.characterCount;
    }

    final updatedSlots = List<BeatCharacterSlot>.from(beat.characterSlots)
      ..add(_emptySlot(who));
    final updatedBeats = List<CascadeBeat>.from(cascade.beats);
    updatedBeats[_state.selectedBeatIndex!] = beat.copyWith(
      characterSlots: updatedSlots,
    );
    _syncCastRoster(cascade.copyWith(beats: updatedBeats));
    notifyListeners();
  }

  void removeCharacterFromActiveBeat(int index) {
    if (_state.activeCascade == null || _state.selectedBeatIndex == null) {
      return;
    }
    final beat = _state.activeCascade!.beats[_state.selectedBeatIndex!];
    if (index < 0 || index >= beat.characterSlots.length) return;

    final updatedSlots = List<BeatCharacterSlot>.from(beat.characterSlots)
      ..removeAt(index);
    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats);
    updatedBeats[_state.selectedBeatIndex!] = beat.copyWith(
      characterSlots: pruneOrphanActionTags(updatedSlots),
    );
    _syncCastRoster(_state.activeCascade!.copyWith(beats: updatedBeats));
    notifyListeners();
  }

  /// Every interaction tags both parties (`source#x` + `target#x`, or
  /// `mutual#x` on each). A tag whose counterpart appears on no *other* slot
  /// has lost its partner, typically because that slot was removed, and is
  /// dropped so a lone `target#hug` never reaches the prompt. The counterpart
  /// is role-aware: `source#x` needs a `target#x`, `target#x` a `source#x`,
  /// `mutual#x` another `mutual#x`; two sources of the same action do not
  /// keep each other alive.
  @visibleForTesting
  static List<BeatCharacterSlot> pruneOrphanActionTags(
    List<BeatCharacterSlot> slots,
  ) {
    (String?, String) split(String tag) {
      final hash = tag.indexOf('#');
      return hash < 0
          ? (null, tag)
          : (tag.substring(0, hash), tag.substring(hash + 1));
    }

    bool isCounterpart(String tag, String other) {
      final (role, action) = split(tag);
      final (otherRole, otherAction) = split(other);
      if (action != otherAction) return false;
      return switch (role) {
        'source' => otherRole == 'target',
        'target' => otherRole == 'source',
        'mutual' => otherRole == 'mutual',
        _ => true, // legacy/unknown role: any same-named action pairs
      };
    }

    bool hasPartner(int self, String tag) {
      for (final (j, other) in slots.indexed) {
        if (j == self) continue;
        if (other.actionTags.any((o) => isCounterpart(tag, o))) {
          return true;
        }
      }
      return false;
    }

    return [
      for (final (i, slot) in slots.indexed)
        slot.actionTags.every((tag) => hasPartner(i, tag))
            ? slot
            : slot.copyWith(
                actionTags: [
                  for (final tag in slot.actionTags)
                    if (hasPartner(i, tag)) tag,
                ],
              ),
    ];
  }

  void reorderCharactersInActiveBeat(int oldIndex, int newIndex) {
    if (_state.activeCascade == null || _state.selectedBeatIndex == null) {
      return;
    }
    final beat = _state.activeCascade!.beats[_state.selectedBeatIndex!];
    if (oldIndex < 0 || oldIndex >= beat.characterSlots.length) return;
    var dest = newIndex;
    if (dest > oldIndex) dest -= 1;
    if (dest < 0 || dest >= beat.characterSlots.length) return;

    final updatedSlots = List<BeatCharacterSlot>.from(beat.characterSlots);
    final item = updatedSlots.removeAt(oldIndex);
    updatedSlots.insert(dest, item);
    updateActiveBeat(beat.copyWith(characterSlots: updatedSlots));
  }

  void setActiveBeatUseCoords(bool useCoords) {
    if (_state.activeCascade == null || _state.selectedBeatIndex == null) {
      return;
    }
    final beat = _state.activeCascade!.beats[_state.selectedBeatIndex!];
    updateActiveBeat(beat.copyWith(useCoords: useCoords));
  }
}
