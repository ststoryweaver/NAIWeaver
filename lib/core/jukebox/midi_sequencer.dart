import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/channel_info.dart';
import 'models/note_block.dart';
import 'synth/midi_synthesizer.dart';

/// A single MIDI event scheduled for playback.
class ScheduledMidiEvent {
  final int absoluteTimeMicros;
  final int type; // 0x90=noteOn, 0x80=noteOff, 0xC0=programChange, 0xB0=CC, 0xE0=pitchBend, 0xFF=meta
  final int channel;
  final int data1;
  final int data2;
  final String? text; // for lyric/text meta events

  const ScheduledMidiEvent({
    required this.absoluteTimeMicros,
    required this.type,
    this.channel = 0,
    this.data1 = 0,
    this.data2 = 0,
    this.text,
  });
}

/// Lyric line parsed from .kar/.mid lyric events.
class LyricLine {
  final String text;
  final Duration timestamp;
  final List<LyricSyllable> syllables;

  const LyricLine({
    required this.text,
    required this.timestamp,
    this.syllables = const [],
  });
}

class LyricSyllable {
  final String text;
  final Duration timestamp;

  const LyricSyllable({required this.text, required this.timestamp});
}

enum SequencerState { stopped, playing, paused }

/// Timer-based MIDI sequencer that dispatches events to a [MidiSynthesizer].
///
/// Parses MIDI files using dart_midi_pro, flattens all tracks into a single
/// sorted timeline, and uses a periodic timer (~2ms / 500Hz) to dispatch events.
class MidiSequencer {
  final MidiSynthesizer _synth;

  SequencerState _state = SequencerState.stopped;
  SequencerState get state => _state;

  List<ScheduledMidiEvent> _events = [];
  int _eventIndex = 0;
  int _startTimeMicros = 0;
  int _pauseOffsetMicros = 0;
  Duration _duration = Duration.zero;
  Timer? _timer;
  double _tempoMultiplier = 1.0;

  // Lyric support
  List<LyricLine> _lyrics = [];
  List<LyricLine> get lyrics => _lyrics;
  void Function(String syllable, Duration timestamp)? onLyric;
  void Function(int channel, int note, int velocity)? onNoteOn;

  // Position tracking
  Duration get position {
    if (_state == SequencerState.playing) {
      final elapsed = DateTime.now().microsecondsSinceEpoch - _startTimeMicros;
      return Duration(microseconds: elapsed);
    }
    return Duration(microseconds: _pauseOffsetMicros);
  }

  Duration get duration => _duration;
  bool get isPlaying => _state == SequencerState.playing;
  bool get isPaused => _state == SequencerState.paused;
  bool get isStopped => _state == SequencerState.stopped;

  MidiSequencer(this._synth);

  /// Public getter for the event timeline.
  List<ScheduledMidiEvent> get events => List.unmodifiable(_events);

  /// Tempo multiplier getter/setter for game tempo control.
  double get tempoMultiplier => _tempoMultiplier;
  set tempoMultiplier(double value) {
    _tempoMultiplier = value.clamp(0.25, 4.0);
  }

  /// Build NoteBlock list by pairing noteOn with noteOff events.
  List<NoteBlock> buildNoteBlocks({int? filterChannel}) {
    final blocks = <NoteBlock>[];
    final activeNotes = <(int, int), ScheduledMidiEvent>{};

    for (final event in _events) {
      if (filterChannel != null && event.channel != filterChannel) continue;
      if (event.type == 0x90 && event.data2 > 0) {
        activeNotes[(event.channel, event.data1)] = event;
      } else if (event.type == 0x80 ||
          (event.type == 0x90 && event.data2 == 0)) {
        final start = activeNotes.remove((event.channel, event.data1));
        if (start != null) {
          blocks.add(NoteBlock(
            note: event.data1,
            channel: event.channel,
            velocity: start.data2,
            startMicros: start.absoluteTimeMicros,
            endMicros: event.absoluteTimeMicros,
            colorIndex: event.data1 % 12,
          ));
        }
      }
    }
    return blocks..sort((a, b) => a.startMicros.compareTo(b.startMicros));
  }

  /// Load and parse a MIDI file from bytes.
  Future<void> load(Uint8List midiBytes) async {
    stop();
    try {
      final result = await compute(_parseMidiFile, midiBytes);
      _events = result.events;
      _lyrics = result.lyrics;
      _duration = result.duration;
      _eventIndex = 0;
      _pauseOffsetMicros = 0;
    } catch (e) {
      debugPrint('MidiSequencer: Failed to parse MIDI: $e');
      _events = [];
      _lyrics = [];
      _duration = Duration.zero;
    }
  }

  /// Start playback from current position.
  void play() {
    if (_events.isEmpty) return;
    if (_state == SequencerState.playing) return;

    _startTimeMicros = DateTime.now().microsecondsSinceEpoch - _pauseOffsetMicros;
    _state = SequencerState.playing;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 2), _tick);
  }

  /// Pause playback.
  void pause() {
    if (_state != SequencerState.playing) return;
    _pauseOffsetMicros = DateTime.now().microsecondsSinceEpoch - _startTimeMicros;
    _state = SequencerState.paused;
    _timer?.cancel();
    _synth.allNotesOff();
  }

  /// Stop playback and reset to beginning.
  void stop() {
    _state = SequencerState.stopped;
    _timer?.cancel();
    _eventIndex = 0;
    _pauseOffsetMicros = 0;
    _synth.allNotesOff();
  }

  /// Seek to a specific position.
  void seek(Duration target) {
    final wasPaused = _state == SequencerState.paused;
    final wasPlaying = _state == SequencerState.playing;

    _synth.allNotesOff();

    final targetMicros = (target.inMicroseconds / _tempoMultiplier).round();

    // Find the event index at or just before the target time
    _eventIndex = 0;
    for (int i = 0; i < _events.length; i++) {
      if (_events[i].absoluteTimeMicros > targetMicros) break;
      _eventIndex = i;

      // Replay program changes and CCs so instruments are correct
      final evt = _events[i];
      if (evt.type == 0xC0) {
        _synth.programChange(evt.channel, evt.data1);
      } else if (evt.type == 0xB0) {
        _synth.controlChange(evt.channel, evt.data1, evt.data2);
      }
    }

    _pauseOffsetMicros = targetMicros;
    if (wasPlaying) {
      _startTimeMicros = DateTime.now().microsecondsSinceEpoch - _pauseOffsetMicros;
    }
    if (wasPaused || wasPlaying) {
      // keep state as-is
    } else {
      _state = SequencerState.paused;
    }
  }

  void _tick(Timer timer) {
    if (_state != SequencerState.playing) return;

    final nowMicros = DateTime.now().microsecondsSinceEpoch - _startTimeMicros;

    while (_eventIndex < _events.length) {
      final evt = _events[_eventIndex];
      final scaledTime = (evt.absoluteTimeMicros * _tempoMultiplier).round();
      if (scaledTime > nowMicros) break;

      _dispatchEvent(evt);
      _eventIndex++;
    }

    // Check if we've reached the end
    if (_eventIndex >= _events.length) {
      stop();
    }
  }

  void _dispatchEvent(ScheduledMidiEvent evt) {
    switch (evt.type) {
      case 0x90: // Note On
        if (evt.data2 == 0) {
          _synth.noteOff(evt.channel, evt.data1);
        } else {
          _synth.noteOn(evt.channel, evt.data1, evt.data2);
          onNoteOn?.call(evt.channel, evt.data1, evt.data2);
        }
      case 0x80: // Note Off
        _synth.noteOff(evt.channel, evt.data1);
      case 0xC0: // Program Change
        _synth.programChange(evt.channel, evt.data1);
      case 0xB0: // Control Change
        _synth.controlChange(evt.channel, evt.data1, evt.data2);
      case 0xE0: // Pitch Bend
        _synth.pitchBend(evt.channel, (evt.data2 << 7) | evt.data1);
      case 0x05: // Lyric meta event
        if (evt.text != null && onLyric != null) {
          onLyric!(evt.text!, Duration(microseconds: evt.absoluteTimeMicros));
        }
    }
  }

  /// Analyze all channels in the loaded MIDI for game song detail.
  List<ChannelInfo> analyzeChannels() {
    if (_events.isEmpty) return [];

    final noteCountPerChannel = <int, int>{};
    final minNotePerChannel = <int, int>{};
    final maxNotePerChannel = <int, int>{};
    final programPerChannel = <int, int>{};
    final firstTimeMicros = <int, int>{};
    final lastTimeMicros = <int, int>{};

    for (final evt in _events) {
      if (evt.type == 0xC0) {
        programPerChannel[evt.channel] = evt.data1;
      }
      if (evt.type == 0x90 && evt.data2 > 0) {
        final ch = evt.channel;
        noteCountPerChannel[ch] = (noteCountPerChannel[ch] ?? 0) + 1;
        final curMin = minNotePerChannel[ch];
        if (curMin == null || evt.data1 < curMin) {
          minNotePerChannel[ch] = evt.data1;
        }
        final curMax = maxNotePerChannel[ch];
        if (curMax == null || evt.data1 > curMax) {
          maxNotePerChannel[ch] = evt.data1;
        }
        if (!firstTimeMicros.containsKey(ch)) {
          firstTimeMicros[ch] = evt.absoluteTimeMicros;
        }
        lastTimeMicros[ch] = evt.absoluteTimeMicros;
      }
    }

    final result = <ChannelInfo>[];
    for (final ch in noteCountPerChannel.keys.toList()..sort()) {
      final count = noteCountPerChannel[ch]!;
      final first = firstTimeMicros[ch] ?? 0;
      final last = lastTimeMicros[ch] ?? 0;
      final durationSec = (last - first) / 1e6;
      final density = durationSec > 0 ? count / durationSec : 0.0;
      final program = programPerChannel[ch] ?? 0;

      result.add(ChannelInfo(
        channel: ch,
        programNumber: program,
        instrumentName: ch == 9 ? 'Drums' : _gmInstrumentName(program),
        noteCount: count,
        minNote: minNotePerChannel[ch] ?? 0,
        maxNote: maxNotePerChannel[ch] ?? 127,
        noteDensity: density,
        isDrums: ch == 9,
      ));
    }

    return result;
  }

  static String _gmInstrumentName(int program) {
    const names = [
      'Acoustic Grand Piano', 'Bright Acoustic Piano', 'Electric Grand Piano',
      'Honky-tonk Piano', 'Electric Piano 1', 'Electric Piano 2', 'Harpsichord',
      'Clavi', 'Celesta', 'Glockenspiel', 'Music Box', 'Vibraphone',
      'Marimba', 'Xylophone', 'Tubular Bells', 'Dulcimer', 'Drawbar Organ',
      'Percussive Organ', 'Rock Organ', 'Church Organ', 'Reed Organ',
      'Accordion', 'Harmonica', 'Tango Accordion', 'Nylon Guitar',
      'Steel Guitar', 'Jazz Guitar', 'Clean Electric Guitar',
      'Muted Electric Guitar', 'Overdriven Guitar', 'Distortion Guitar',
      'Guitar Harmonics', 'Acoustic Bass', 'Electric Bass (Finger)',
      'Electric Bass (Pick)', 'Fretless Bass', 'Slap Bass 1', 'Slap Bass 2',
      'Synth Bass 1', 'Synth Bass 2', 'Violin', 'Viola', 'Cello',
      'Contrabass', 'Tremolo Strings', 'Pizzicato Strings', 'Orchestral Harp',
      'Timpani', 'String Ensemble 1', 'String Ensemble 2', 'SynthStrings 1',
      'SynthStrings 2', 'Choir Aahs', 'Voice Oohs', 'Synth Voice',
      'Orchestra Hit', 'Trumpet', 'Trombone', 'Tuba', 'Muted Trumpet',
      'French Horn', 'Brass Section', 'SynthBrass 1', 'SynthBrass 2',
      'Soprano Sax', 'Alto Sax', 'Tenor Sax', 'Baritone Sax', 'Oboe',
      'English Horn', 'Bassoon', 'Clarinet', 'Piccolo', 'Flute', 'Recorder',
      'Pan Flute', 'Blown Bottle', 'Shakuhachi', 'Whistle', 'Ocarina',
      'Lead 1 (Square)', 'Lead 2 (Sawtooth)', 'Lead 3 (Calliope)',
      'Lead 4 (Chiff)', 'Lead 5 (Charang)', 'Lead 6 (Voice)',
      'Lead 7 (Fifths)', 'Lead 8 (Bass + Lead)', 'Pad 1 (New Age)',
      'Pad 2 (Warm)', 'Pad 3 (Polysynth)', 'Pad 4 (Choir)',
      'Pad 5 (Bowed)', 'Pad 6 (Metallic)', 'Pad 7 (Halo)',
      'Pad 8 (Sweep)', 'FX 1 (Rain)', 'FX 2 (Soundtrack)',
      'FX 3 (Crystal)', 'FX 4 (Atmosphere)', 'FX 5 (Brightness)',
      'FX 6 (Goblins)', 'FX 7 (Echoes)', 'FX 8 (Sci-fi)', 'Sitar',
      'Banjo', 'Shamisen', 'Koto', 'Kalimba', 'Bag pipe', 'Fiddle',
      'Shanai', 'Tinkle Bell', 'Agogo', 'Steel Drums', 'Woodblock',
      'Taiko Drum', 'Melodic Tom', 'Synth Drum', 'Reverse Cymbal',
      'Guitar Fret Noise', 'Breath Noise', 'Seashore', 'Bird Tweet',
      'Telephone Ring', 'Helicopter', 'Applause', 'Gunshot',
    ];
    if (program < 0 || program >= names.length) return 'Unknown';
    return names[program];
  }

  void dispose() {
    stop();
    _timer?.cancel();
  }
}

/// Result of MIDI file parsing, computed in an isolate.
class _ParseResult {
  final List<ScheduledMidiEvent> events;
  final List<LyricLine> lyrics;
  final Duration duration;

  const _ParseResult({
    required this.events,
    required this.lyrics,
    required this.duration,
  });
}

/// Parses a MIDI file into sorted events and lyrics. Runs in an isolate.
_ParseResult _parseMidiFile(Uint8List bytes) {
  // Using dart_midi_pro to parse
  // Import is dynamic here since this runs in compute()
  try {
    return _parseMidiBytes(bytes);
  } catch (e) {
    return const _ParseResult(
      events: [],
      lyrics: [],
      duration: Duration.zero,
    );
  }
}

_ParseResult _parseMidiBytes(Uint8List bytes) {
  // Manual MIDI file parser — Standard MIDI File format
  if (bytes.length < 14) {
    return const _ParseResult(events: [], lyrics: [], duration: Duration.zero);
  }

  final data = ByteData.sublistView(bytes);
  int pos = 0;

  // Read header chunk "MThd"
  if (bytes[0] != 0x4D || bytes[1] != 0x54 || bytes[2] != 0x68 || bytes[3] != 0x64) {
    return const _ParseResult(events: [], lyrics: [], duration: Duration.zero);
  }
  pos += 4;

  final headerLength = data.getUint32(pos);
  pos += 4;
  data.getUint16(pos); // format (0, 1, or 2) — not needed for playback
  pos += 2;
  final numTracks = data.getUint16(pos);
  pos += 2;
  final division = data.getUint16(pos);
  pos += 2;

  // Skip any extra header bytes
  pos = 8 + headerLength.toInt();

  final bool isSMPTE = (division & 0x8000) != 0;
  final int ticksPerQuarter = isSMPTE ? 480 : division;

  // Tempo map: list of (tick, microsPerBeat)
  final tempoMap = <(int, int)>[(0, 500000)]; // default 120 BPM

  final allEvents = <ScheduledMidiEvent>[];
  final lyricEvents = <(int, String)>[]; // (timeMicros, text)

  for (int trackIdx = 0; trackIdx < numTracks && pos < bytes.length - 8; trackIdx++) {
    // Read track chunk "MTrk"
    if (bytes[pos] != 0x4D || bytes[pos + 1] != 0x54 ||
        bytes[pos + 2] != 0x72 || bytes[pos + 3] != 0x6B) {
      // Not a valid track chunk, try to skip
      break;
    }
    pos += 4;
    final trackLength = data.getUint32(pos);
    pos += 4;
    final trackEnd = pos + trackLength.toInt();

    int tick = 0;
    int runningStatus = 0;

    while (pos < trackEnd && pos < bytes.length) {
      // Read delta time (variable-length)
      int delta = 0;
      while (pos < bytes.length) {
        final b = bytes[pos++];
        delta = (delta << 7) | (b & 0x7F);
        if ((b & 0x80) == 0) break;
      }
      tick += delta;

      if (pos >= bytes.length) break;

      int statusByte = bytes[pos];

      // Handle running status
      if (statusByte < 0x80) {
        statusByte = runningStatus;
      } else {
        pos++;
        if (statusByte < 0xF0) {
          runningStatus = statusByte;
        }
      }

      final type = statusByte & 0xF0;
      final channel = statusByte & 0x0F;

      if (type == 0x80 || type == 0x90 || type == 0xA0 || type == 0xB0 || type == 0xE0) {
        // Two data bytes
        if (pos + 1 >= bytes.length) break;
        final d1 = bytes[pos++];
        final d2 = bytes[pos++];
        allEvents.add(ScheduledMidiEvent(
          absoluteTimeMicros: tick, // Will be converted from ticks later
          type: type,
          channel: channel,
          data1: d1,
          data2: d2,
        ));
      } else if (type == 0xC0 || type == 0xD0) {
        // One data byte
        if (pos >= bytes.length) break;
        final d1 = bytes[pos++];
        allEvents.add(ScheduledMidiEvent(
          absoluteTimeMicros: tick,
          type: type,
          channel: channel,
          data1: d1,
        ));
      } else if (statusByte == 0xFF) {
        // Meta event
        if (pos + 1 >= bytes.length) break;
        final metaType = bytes[pos++];
        int len = 0;
        while (pos < bytes.length) {
          final b = bytes[pos++];
          len = (len << 7) | (b & 0x7F);
          if ((b & 0x80) == 0) break;
        }
        if (pos + len > bytes.length) break;

        if (metaType == 0x51 && len == 3) {
          // Tempo change
          final tempo = (bytes[pos] << 16) | (bytes[pos + 1] << 8) | bytes[pos + 2];
          tempoMap.add((tick, tempo));
        } else if (metaType == 0x05 || metaType == 0x01) {
          // Lyric (0x05) or Text (0x01) event
          final text = String.fromCharCodes(bytes.sublist(pos, pos + len));
          lyricEvents.add((tick, text));
          allEvents.add(ScheduledMidiEvent(
            absoluteTimeMicros: tick,
            type: 0x05,
            text: text,
          ));
        }
        pos += len;
      } else if (statusByte == 0xF0 || statusByte == 0xF7) {
        // SysEx
        int len = 0;
        while (pos < bytes.length) {
          final b = bytes[pos++];
          len = (len << 7) | (b & 0x7F);
          if ((b & 0x80) == 0) break;
        }
        pos += len;
      }
    }

    pos = trackEnd;
  }

  // Sort tempo map by tick
  tempoMap.sort((a, b) => a.$1.compareTo(b.$1));

  // Convert ticks to microseconds using tempo map
  int tickToMicros(int tick) {
    int micros = 0;
    int prevTick = 0;
    int currentTempo = 500000;

    for (final (tempoTick, tempo) in tempoMap) {
      if (tempoTick >= tick) break;
      micros += ((tempoTick - prevTick) * currentTempo) ~/ ticksPerQuarter;
      prevTick = tempoTick;
      currentTempo = tempo;
    }
    micros += ((tick - prevTick) * currentTempo) ~/ ticksPerQuarter;
    return micros;
  }

  // Convert all event ticks to microseconds
  final convertedEvents = allEvents.map((e) {
    return ScheduledMidiEvent(
      absoluteTimeMicros: tickToMicros(e.absoluteTimeMicros),
      type: e.type,
      channel: e.channel,
      data1: e.data1,
      data2: e.data2,
      text: e.text,
    );
  }).toList();

  // Sort by time
  convertedEvents.sort((a, b) => a.absoluteTimeMicros.compareTo(b.absoluteTimeMicros));

  // Build lyric lines
  final parsedLyrics = <LyricLine>[];
  final syllables = <LyricSyllable>[];
  final lineBuffer = StringBuffer();

  for (final (tick, text) in lyricEvents) {
    final timeMicros = tickToMicros(tick);
    final ts = Duration(microseconds: timeMicros);

    if (text.contains('\n') || text.contains('\r') || text.startsWith('/') || text.startsWith('\\')) {
      // New line
      if (lineBuffer.isNotEmpty) {
        parsedLyrics.add(LyricLine(
          text: lineBuffer.toString().trim(),
          timestamp: syllables.isNotEmpty ? syllables.first.timestamp : ts,
          syllables: List.of(syllables),
        ));
        lineBuffer.clear();
        syllables.clear();
      }
      final cleaned = text.replaceAll(RegExp(r'[\n\r/\\]'), '');
      if (cleaned.isNotEmpty) {
        syllables.add(LyricSyllable(text: cleaned, timestamp: ts));
        lineBuffer.write(cleaned);
      }
    } else {
      syllables.add(LyricSyllable(text: text, timestamp: ts));
      lineBuffer.write(text);
    }
  }
  if (lineBuffer.isNotEmpty) {
    parsedLyrics.add(LyricLine(
      text: lineBuffer.toString().trim(),
      timestamp: syllables.isNotEmpty ? syllables.first.timestamp : Duration.zero,
      syllables: List.of(syllables),
    ));
  }

  // Calculate total duration
  final lastEventTime = convertedEvents.isNotEmpty
      ? convertedEvents.last.absoluteTimeMicros
      : 0;
  final totalDuration = Duration(microseconds: lastEventTime);

  return _ParseResult(
    events: convertedEvents,
    lyrics: parsedLyrics,
    duration: totalDuration,
  );
}
