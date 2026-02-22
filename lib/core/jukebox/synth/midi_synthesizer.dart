import 'dart:io';
import 'fluidsynth_synthesizer.dart';
import 'mobile_synthesizer.dart';

/// Abstract interface for platform MIDI synthesis.
abstract class MidiSynthesizer {
  Future<void> initialize();
  Future<void> loadSoundFont(String path);
  void noteOn(int channel, int note, int velocity);
  void noteOff(int channel, int note);
  void programChange(int channel, int program);
  void controlChange(int channel, int controller, int value);
  void pitchBend(int channel, int value);
  void allNotesOff();
  void systemReset();
  bool get isAvailable;
  Future<void> dispose();

  /// Factory to create the appropriate synthesizer for the current platform.
  static MidiSynthesizer create() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return FluidSynthSynthesizer();
    }
    return MobileSynthesizer();
  }
}
