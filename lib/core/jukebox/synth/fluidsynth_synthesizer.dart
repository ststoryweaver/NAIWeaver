import 'dart:ffi';
import 'package:flutter/foundation.dart';
import '../native/fluidsynth_bindings.dart';
import 'midi_synthesizer.dart';

/// Windows/Linux/macOS synthesizer using FluidSynth via dart:ffi.
class FluidSynthSynthesizer implements MidiSynthesizer {
  FluidSynthBindings? _bindings;
  Pointer? _settings;
  Pointer? _synth;
  Pointer? _audioDriver;
  int? _currentSfId;
  bool _initialized = false;

  @override
  bool get isAvailable => _bindings != null;

  @override
  Future<void> initialize() async {
    _bindings = FluidSynthBindings.tryLoad();
    if (_bindings == null) {
      debugPrint('FluidSynth: DLL not found, music playback unavailable');
      return;
    }

    _settings = _bindings!.newSettings();
    if (_settings == null || _settings == nullptr) {
      debugPrint('FluidSynth: Failed to create settings');
      _bindings = null;
      return;
    }

    // Configure audio output
    _bindings!.settingsSetStr(_settings!, 'audio.driver', 'wasapi');
    _bindings!.settingsSetNum(_settings!, 'synth.sample-rate', 44100.0);
    _bindings!.settingsSetNum(_settings!, 'synth.gain', 0.6);
    _bindings!.settingsSetInt(_settings!, 'synth.polyphony', 256);

    _synth = _bindings!.newSynth(_settings!);
    if (_synth == null || _synth == nullptr) {
      debugPrint('FluidSynth: Failed to create synth');
      _bindings!.deleteSettings(_settings!);
      _bindings = null;
      return;
    }

    _audioDriver = _bindings!.newAudioDriver(_settings!, _synth!);
    if (_audioDriver == null || _audioDriver == nullptr) {
      debugPrint('FluidSynth: Failed to create audio driver, trying dsound');
      // Fallback to DirectSound
      _bindings!.settingsSetStr(_settings!, 'audio.driver', 'dsound');
      _bindings!.deleteSynth(_synth!);
      _synth = _bindings!.newSynth(_settings!);
      _audioDriver = _bindings!.newAudioDriver(_settings!, _synth!);
      if (_audioDriver == null || _audioDriver == nullptr) {
        debugPrint('FluidSynth: All audio drivers failed');
        _bindings!.deleteSynth(_synth!);
        _bindings!.deleteSettings(_settings!);
        _bindings = null;
        return;
      }
    }

    _initialized = true;
  }

  @override
  Future<void> loadSoundFont(String path) async {
    if (!_initialized || _bindings == null) return;

    // Unload previous soundfont
    if (_currentSfId != null) {
      _bindings!.sfUnload(_synth!, _currentSfId!);
      _currentSfId = null;
    }

    final sfId = _bindings!.sfLoad(_synth!, path);
    if (sfId < 0) {
      debugPrint('FluidSynth: Failed to load soundfont: $path');
      return;
    }
    _currentSfId = sfId;
  }

  @override
  void noteOn(int channel, int note, int velocity) {
    if (!_initialized || _bindings == null) return;
    _bindings!.noteOn(_synth!, channel, note, velocity);
  }

  @override
  void noteOff(int channel, int note) {
    if (!_initialized || _bindings == null) return;
    _bindings!.noteOff(_synth!, channel, note);
  }

  @override
  void programChange(int channel, int program) {
    if (!_initialized || _bindings == null) return;
    _bindings!.programChange(_synth!, channel, program);
  }

  @override
  void controlChange(int channel, int controller, int value) {
    if (!_initialized || _bindings == null) return;
    _bindings!.cc(_synth!, channel, controller, value);
  }

  @override
  void pitchBend(int channel, int value) {
    if (!_initialized || _bindings == null) return;
    _bindings!.pitchBend(_synth!, channel, value);
  }

  @override
  void allNotesOff() {
    if (!_initialized || _bindings == null) return;
    for (int ch = 0; ch < 16; ch++) {
      // CC 123 = All Notes Off
      _bindings!.cc(_synth!, ch, 123, 0);
      // CC 120 = All Sound Off
      _bindings!.cc(_synth!, ch, 120, 0);
    }
  }

  @override
  void systemReset() {
    if (!_initialized || _bindings == null) return;
    _bindings!.systemReset(_synth!);
  }

  @override
  Future<void> dispose() async {
    if (!_initialized || _bindings == null) return;
    allNotesOff();

    if (_audioDriver != null && _audioDriver != nullptr) {
      _bindings!.deleteAudioDriver(_audioDriver!);
      _audioDriver = null;
    }
    if (_synth != null && _synth != nullptr) {
      _bindings!.deleteSynth(_synth!);
      _synth = null;
    }
    if (_settings != null && _settings != nullptr) {
      _bindings!.deleteSettings(_settings!);
      _settings = null;
    }
    _currentSfId = null;
    _initialized = false;
  }
}
