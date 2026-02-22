import 'dart:io';
import 'fluidsynth_synthesizer.dart';
import 'midi_synthesizer.dart';
import 'mobile_synthesizer.dart';

MidiSynthesizer createSynthesizer() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return FluidSynthSynthesizer();
  }
  return MobileSynthesizer();
}
