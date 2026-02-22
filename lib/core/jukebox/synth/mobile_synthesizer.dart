import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'midi_synthesizer.dart';

/// Android/iOS synthesizer using flutter_midi_pro.
///
/// This implementation wraps flutter_midi_pro for mobile platforms.
/// On platforms where flutter_midi_pro is unavailable, operations are no-ops.
class MobileSynthesizer implements MidiSynthesizer {
  MidiPro? _midiPro;
  bool _initialized = false;
  int _sfId = -1;

  @override
  bool get isAvailable => _initialized;

  @override
  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    try {
      _midiPro = MidiPro();
      _initialized = true;
    } catch (e) {
      debugPrint('MobileSynthesizer: Init failed: $e');
    }
  }

  @override
  Future<void> loadSoundFont(String path) async {
    if (!_initialized || _midiPro == null) return;
    try {
      _sfId = await _midiPro!.loadSoundfontFile(filePath: path);
    } catch (e) {
      debugPrint('MobileSynthesizer: Failed to load soundfont: $e');
    }
  }

  @override
  void noteOn(int channel, int note, int velocity) {
    if (!_initialized || _sfId < 0) return;
    _midiPro!.playNote(channel: channel, key: note, velocity: velocity, sfId: _sfId);
  }

  @override
  void noteOff(int channel, int note) {
    if (!_initialized || _sfId < 0) return;
    _midiPro!.stopNote(channel: channel, key: note, sfId: _sfId);
  }

  @override
  void programChange(int channel, int program) {
    if (!_initialized || _sfId < 0) return;
    _midiPro!.selectInstrument(sfId: _sfId, program: program, channel: channel);
  }

  @override
  void controlChange(int channel, int controller, int value) {
    if (!_initialized || _sfId < 0) return;
    _midiPro!.controlChange(controller: controller, value: value, channel: channel, sfId: _sfId);
  }

  @override
  void pitchBend(int channel, int value) {
    // flutter_midi_pro doesn't support pitch bend — no-op
  }

  @override
  void allNotesOff() {
    if (!_initialized || _sfId < 0) return;
    _midiPro!.stopAllNotes(sfId: _sfId);
  }

  @override
  void systemReset() {
    allNotesOff();
  }

  @override
  Future<void> dispose() async {
    if (_midiPro != null) {
      allNotesOff();
      _midiPro!.dispose();
    }
    _midiPro = null;
    _initialized = false;
    _sfId = -1;
  }
}
