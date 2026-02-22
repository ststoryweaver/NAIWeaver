import 'dart:async';
import 'package:flutter/foundation.dart';
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
      debugPrint('MidiSequencer: Loaded ${_events.length} events, ${_lyrics.length} lyric lines, duration=${_duration.inSeconds}s');
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

  /// Set tempo multiplier (1.0 = normal, 0.5 = half speed, 2.0 = double speed).
  void setTempo(double multiplier) {
    _tempoMultiplier = multiplier.clamp(0.25, 4.0);
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
