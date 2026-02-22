import 'package:audio_service/audio_service.dart';
import '../providers/jukebox_notifier.dart';

class JukeboxAudioHandler extends BaseAudioHandler with SeekHandler {
  JukeboxNotifier? _notifier;
  Duration _lastReportedPosition = Duration.zero;

  void attachNotifier(JukeboxNotifier notifier) {
    _notifier = notifier;
    notifier.addListener(_syncState);
    // Sync initial state
    _syncState();
  }

  void _syncState() {
    final n = _notifier;
    if (n == null) return;

    // Update mediaItem
    final song = n.currentSong;
    if (song != null) {
      final duration = n.duration;
      final item = MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist ?? song.categoryLabel,
        album: 'NAIWeaver Jukebox',
        duration: duration,
      );
      mediaItem.add(item);
    } else {
      mediaItem.add(null);
    }

    // Throttle position updates — only emit when state changes or position moves 500ms+
    final pos = n.position;
    final positionChanged =
        (pos - _lastReportedPosition).abs() > const Duration(milliseconds: 500);
    final isPlaying = n.isPlaying;

    if (positionChanged || isPlaying != playbackState.value.playing) {
      _lastReportedPosition = pos;

      playbackState.add(PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: song != null
            ? AudioProcessingState.ready
            : AudioProcessingState.idle,
        playing: isPlaying,
        updatePosition: pos,
      ));
    }
  }

  @override
  Future<void> play() async {
    _notifier?.resume();
  }

  @override
  Future<void> pause() async {
    _notifier?.pause();
  }

  @override
  Future<void> stop() async {
    _notifier?.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    await _notifier?.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await _notifier?.previous();
  }

  @override
  Future<void> seek(Duration position) async {
    _notifier?.seek(position);
  }
}
