import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// dart:ffi bindings for FluidSynth (libfluidsynth-3.dll on Windows).
class FluidSynthBindings {
  final DynamicLibrary _lib;

  FluidSynthBindings(this._lib);

  /// Attempts to load FluidSynth from the bundled DLL next to the executable,
  /// falling back to name-only search for dev/Linux scenarios.
  static FluidSynthBindings? tryLoad() {
    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final lib = DynamicLibrary.open(p.join(exeDir, 'libfluidsynth-3.dll'));
      return FluidSynthBindings(lib);
    } catch (_) {
      try {
        final lib = DynamicLibrary.open('libfluidsynth-3.dll');
        return FluidSynthBindings(lib);
      } catch (_) {
        return null;
      }
    }
  }

  // --- Settings ---

  late final _newSettings = _lib.lookupFunction<
      Pointer Function(),
      Pointer Function()>('new_fluid_settings');

  Pointer newSettings() => _newSettings();

  late final _deleteSettings = _lib.lookupFunction<
      Void Function(Pointer),
      void Function(Pointer)>('delete_fluid_settings');

  void deleteSettings(Pointer settings) => _deleteSettings(settings);

  late final _settingsSetStr = _lib.lookupFunction<
      Int32 Function(Pointer, Pointer<Utf8>, Pointer<Utf8>),
      int Function(Pointer, Pointer<Utf8>, Pointer<Utf8>)>('fluid_settings_setstr');

  int settingsSetStr(Pointer settings, String name, String value) {
    final namePtr = name.toNativeUtf8();
    final valuePtr = value.toNativeUtf8();
    final result = _settingsSetStr(settings, namePtr, valuePtr);
    calloc.free(namePtr);
    calloc.free(valuePtr);
    return result;
  }

  late final _settingsSetNum = _lib.lookupFunction<
      Int32 Function(Pointer, Pointer<Utf8>, Double),
      int Function(Pointer, Pointer<Utf8>, double)>('fluid_settings_setnum');

  int settingsSetNum(Pointer settings, String name, double value) {
    final namePtr = name.toNativeUtf8();
    final result = _settingsSetNum(settings, namePtr, value);
    calloc.free(namePtr);
    return result;
  }

  late final _settingsSetInt = _lib.lookupFunction<
      Int32 Function(Pointer, Pointer<Utf8>, Int32),
      int Function(Pointer, Pointer<Utf8>, int)>('fluid_settings_setint');

  int settingsSetInt(Pointer settings, String name, int value) {
    final namePtr = name.toNativeUtf8();
    final result = _settingsSetInt(settings, namePtr, value);
    calloc.free(namePtr);
    return result;
  }

  // --- Synth ---

  late final _newSynth = _lib.lookupFunction<
      Pointer Function(Pointer),
      Pointer Function(Pointer)>('new_fluid_synth');

  Pointer newSynth(Pointer settings) => _newSynth(settings);

  late final _deleteSynth = _lib.lookupFunction<
      Void Function(Pointer),
      void Function(Pointer)>('delete_fluid_synth');

  void deleteSynth(Pointer synth) => _deleteSynth(synth);

  // --- Audio Driver ---

  late final _newAudioDriver = _lib.lookupFunction<
      Pointer Function(Pointer, Pointer),
      Pointer Function(Pointer, Pointer)>('new_fluid_audio_driver');

  Pointer newAudioDriver(Pointer settings, Pointer synth) =>
      _newAudioDriver(settings, synth);

  late final _deleteAudioDriver = _lib.lookupFunction<
      Void Function(Pointer),
      void Function(Pointer)>('delete_fluid_audio_driver');

  void deleteAudioDriver(Pointer driver) => _deleteAudioDriver(driver);

  // --- SoundFont ---

  late final _sfLoad = _lib.lookupFunction<
      Int32 Function(Pointer, Pointer<Utf8>, Int32),
      int Function(Pointer, Pointer<Utf8>, int)>('fluid_synth_sfload');

  int sfLoad(Pointer synth, String path, {bool resetPresets = true}) {
    final pathPtr = path.toNativeUtf8();
    final result = _sfLoad(synth, pathPtr, resetPresets ? 1 : 0);
    calloc.free(pathPtr);
    return result;
  }

  late final _sfUnload = _lib.lookupFunction<
      Int32 Function(Pointer, Int32, Int32),
      int Function(Pointer, int, int)>('fluid_synth_sfunload');

  int sfUnload(Pointer synth, int sfId, {bool resetPresets = true}) =>
      _sfUnload(synth, sfId, resetPresets ? 1 : 0);

  // --- MIDI Events ---

  late final _noteOn = _lib.lookupFunction<
      Int32 Function(Pointer, Int32, Int32, Int32),
      int Function(Pointer, int, int, int)>('fluid_synth_noteon');

  int noteOn(Pointer synth, int channel, int key, int velocity) =>
      _noteOn(synth, channel, key, velocity);

  late final _noteOff = _lib.lookupFunction<
      Int32 Function(Pointer, Int32, Int32),
      int Function(Pointer, int, int)>('fluid_synth_noteoff');

  int noteOff(Pointer synth, int channel, int key) =>
      _noteOff(synth, channel, key);

  late final _programChange = _lib.lookupFunction<
      Int32 Function(Pointer, Int32, Int32),
      int Function(Pointer, int, int)>('fluid_synth_program_change');

  int programChange(Pointer synth, int channel, int program) =>
      _programChange(synth, channel, program);

  late final _cc = _lib.lookupFunction<
      Int32 Function(Pointer, Int32, Int32, Int32),
      int Function(Pointer, int, int, int)>('fluid_synth_cc');

  int cc(Pointer synth, int channel, int controller, int value) =>
      _cc(synth, channel, controller, value);

  late final _pitchBend = _lib.lookupFunction<
      Int32 Function(Pointer, Int32, Int32),
      int Function(Pointer, int, int)>('fluid_synth_pitch_bend');

  int pitchBend(Pointer synth, int channel, int value) =>
      _pitchBend(synth, channel, value);

  late final _systemReset = _lib.lookupFunction<
      Int32 Function(Pointer),
      int Function(Pointer)>('fluid_synth_system_reset');

  int systemReset(Pointer synth) => _systemReset(synth);
}
