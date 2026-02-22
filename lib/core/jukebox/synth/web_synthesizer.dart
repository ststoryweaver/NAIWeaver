import 'midi_synthesizer.dart';

/// No-op synthesizer for web where dart:ffi and dart:io are unavailable.
class WebSynthesizer implements MidiSynthesizer {
  @override
  bool get isAvailable => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadSoundFont(String path) async {}

  @override
  void noteOn(int channel, int note, int velocity) {}

  @override
  void noteOff(int channel, int note) {}

  @override
  void programChange(int channel, int program) {}

  @override
  void controlChange(int channel, int controller, int value) {}

  @override
  void pitchBend(int channel, int value) {}

  @override
  void allNotesOff() {}

  @override
  void systemReset() {}

  @override
  Future<void> dispose() async {}
}

MidiSynthesizer createSynthesizer() => WebSynthesizer();
