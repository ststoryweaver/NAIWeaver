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
  final String globalInjection;
  final Map<int, Uint8List?> beatPreviews;

  CascadeState({
    this.savedCascades = const [],
    this.activeCascade,
    this.selectedBeatIndex,
    this.isLoading = false,
    this.characterAppearances = const [],
    this.globalInjection = "",
    this.beatPreviews = const {},
  });

  CascadeState copyWith({
    List<PromptCascade>? savedCascades,
    PromptCascade? activeCascade,
    bool clearActiveCascade = false,
    int? selectedBeatIndex,
    bool clearSelectedBeatIndex = false,
    bool? isLoading,
    List<String>? characterAppearances,
    String? globalInjection,
    Map<int, Uint8List?>? beatPreviews,
  }) {
    return CascadeState(
      savedCascades: savedCascades ?? this.savedCascades,
      activeCascade: clearActiveCascade ? null : (activeCascade ?? this.activeCascade),
      selectedBeatIndex: clearSelectedBeatIndex ? null : (selectedBeatIndex ?? this.selectedBeatIndex),
      isLoading: isLoading ?? this.isLoading,
      characterAppearances: characterAppearances ?? this.characterAppearances,
      globalInjection: globalInjection ?? this.globalInjection,
      beatPreviews: beatPreviews ?? this.beatPreviews,
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
      final jsonString = json.encode(_state.savedCascades.map((e) => e.toJson()).toList());
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
      characterAppearances: cascade != null ? List.generate(cascade.characterCount, (_) => "") : [],
      globalInjection: "",
      beatPreviews: {},
    );
    notifyListeners();
  }

  void exitCascadeMode() {
    _state = _state.copyWith(
      clearActiveCascade: true,
      clearSelectedBeatIndex: true,
      characterAppearances: [],
      globalInjection: "",
      beatPreviews: {},
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

  void updateGlobalInjection(String val) {
    _state = _state.copyWith(globalInjection: val);
    notifyListeners();
  }

  void setBeatPreview(int index, Uint8List? bytes) {
    final updated = Map<int, Uint8List?>.from(_state.beatPreviews);
    updated[index] = bytes;
    _state = _state.copyWith(beatPreviews: updated);
    notifyListeners();
  }

  void selectBeat(int index) {
    if (_state.activeCascade == null || index < 0 || index >= _state.activeCascade!.beats.length) return;
    _state = _state.copyWith(selectedBeatIndex: index);
    notifyListeners();
  }

  void createNewCascade(String name, int characterCount, {bool useCoords = true}) {
    final newCascade = PromptCascade(
      name: name,
      characterCount: characterCount,
      useCoords: useCoords,
      beats: [
        // Start with one empty beat
        CascadeBeat(
          characterSlots: List.generate(
            characterCount,
            (_) => BeatCharacterSlot(position: NaiCoordinate(x: 2, y: 2)),
          ),
          environmentTags: "",
        ),
      ],
    );
    _savedSnapshot = null; // Never saved yet → always dirty
    _state = _state.copyWith(activeCascade: newCascade, selectedBeatIndex: 0);
    notifyListeners();
  }

  void saveActiveToLibrary() {
    if (_state.activeCascade == null) return;

    final existingIndex = _state.savedCascades.indexWhere((c) => c.name == _state.activeCascade!.name);
    List<PromptCascade> updatedList;
    if (existingIndex >= 0) {
      updatedList = List<PromptCascade>.from(_state.savedCascades)..[existingIndex] = _state.activeCascade!;
    } else {
      updatedList = List<PromptCascade>.from(_state.savedCascades)..add(_state.activeCascade!);
    }

    _savedSnapshot = json.encode(_state.activeCascade!.toJson());
    _state = _state.copyWith(savedCascades: updatedList);
    _saveToStorage();
    notifyListeners();
  }

  void deleteCascade(String name) {
    final updatedList = _state.savedCascades.where((c) => c.name != name).toList();
    _state = _state.copyWith(savedCascades: updatedList);
    if (_state.activeCascade?.name == name) {
      _state = _state.copyWith(activeCascade: null, selectedBeatIndex: null);
    }
    _saveToStorage();
    notifyListeners();
  }

  void addBeat() {
    if (_state.activeCascade == null) return;
    
    final newBeat = CascadeBeat(
      characterSlots: List.generate(
        _state.activeCascade!.characterCount,
        (_) => BeatCharacterSlot(position: NaiCoordinate(x: 2, y: 2)),
      ),
      environmentTags: _state.activeCascade!.beats.isNotEmpty 
          ? _state.activeCascade!.beats.last.environmentTags 
          : "",
    );
    
    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats)..add(newBeat);
    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
      selectedBeatIndex: updatedBeats.length - 1,
    );
    notifyListeners();
  }

  void cloneBeat(int index) {
    if (_state.activeCascade == null || index < 0 || index >= _state.activeCascade!.beats.length) return;
    
    final sourceBeat = _state.activeCascade!.beats[index];
    final clonedBeat = CascadeBeat(
      characterSlots: sourceBeat.characterSlots.map((s) => BeatCharacterSlot(
        position: s.position,
        actionTag: s.actionTag,
        positivePrompt: s.positivePrompt,
        negativePrompt: s.negativePrompt,
      )).toList(),
      environmentTags: sourceBeat.environmentTags,
      sampler: sourceBeat.sampler,
      steps: sourceBeat.steps,
      scale: sourceBeat.scale,
    );
    
    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats)..insert(index + 1, clonedBeat);
    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
      selectedBeatIndex: index + 1,
    );
    notifyListeners();
  }

  void removeBeat(int index) {
    if (_state.activeCascade == null || _state.activeCascade!.beats.length <= 1) return;
    
    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats)..removeAt(index);
    int? newSelectedIndex = _state.selectedBeatIndex;
    if (newSelectedIndex != null) {
      if (newSelectedIndex >= updatedBeats.length) {
        newSelectedIndex = updatedBeats.length - 1;
      }
    }
    
    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
      selectedBeatIndex: newSelectedIndex,
    );
    notifyListeners();
  }

  void reorderBeats(int oldIndex, int newIndex) {
    if (_state.activeCascade == null) return;
    
    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updatedBeats.removeAt(oldIndex);
    updatedBeats.insert(newIndex, item);
    
    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
      selectedBeatIndex: newIndex,
    );
    notifyListeners();
  }

  void updateActiveBeat(CascadeBeat updatedBeat) {
    if (_state.activeCascade == null || _state.selectedBeatIndex == null) return;
    
    final updatedBeats = List<CascadeBeat>.from(_state.activeCascade!.beats);
    updatedBeats[_state.selectedBeatIndex!] = updatedBeat;
    
    _state = _state.copyWith(
      activeCascade: _state.activeCascade!.copyWith(beats: updatedBeats),
    );
    notifyListeners();
  }
}
