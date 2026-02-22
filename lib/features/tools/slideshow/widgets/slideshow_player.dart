import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/jukebox/jukebox_registry.dart';
import '../../../../core/jukebox/models/jukebox_song.dart';
import '../../../../core/jukebox/providers/jukebox_notifier.dart';
import '../../../../core/jukebox/widgets/karaoke_overlay.dart';
import '../../jukebox/widgets/jukebox_panel.dart';
import '../../../gallery/providers/gallery_notifier.dart';
import '../models/slideshow_config.dart';
import '../services/slideshow_animation_service.dart';

class SlideshowPlayer extends StatefulWidget {
  final SlideshowConfig config;
  final List<GalleryItem> playlist;

  const SlideshowPlayer({
    super.key,
    required this.config,
    required this.playlist,
  });

  @override
  State<SlideshowPlayer> createState() => _SlideshowPlayerState();
}

class _SlideshowPlayerState extends State<SlideshowPlayer>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  bool _isPlaying = true;
  bool _showControls = true;
  Timer? _slideTimer;
  Timer? _hideControlsTimer;
  late AnimationController _kenBurnsController;
  KenBurnsAnimation? _kenBurns;
  final FocusNode _focusNode = FocusNode();

  // Preloaded next image
  ImageProvider? _nextImageProvider;

  // Manual zoom controller
  final TransformationController _manualZoomController = TransformationController();
  bool _showKaraoke = false;
  bool _musicMuted = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _kenBurnsController = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: (widget.config.slideDuration * 1000).round()),
    );
    _startKenBurns();
    _scheduleSlide();
    _scheduleHideControls();
    _showKaraoke = widget.config.karaokeEnabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _preloadNext();
      _startMusic();
    });
  }

  void _startMusic() {
    if (!widget.config.musicEnabled) return;
    if (!mounted) return;

    final jukebox = context.read<JukeboxNotifier>();
    if (!jukebox.synthAvailable) return;

    // Determine songs to play
    List<JukeboxSong> songs;
    if (widget.config.musicSongIds.isNotEmpty) {
      songs = widget.config.musicSongIds
          .map((id) => JukeboxRegistry.findSongById(id))
          .whereType<JukeboxSong>()
          .toList();
    } else if (widget.config.musicCategoryIndex != null) {
      final cat = SongCategory.values[widget.config.musicCategoryIndex!];
      songs = JukeboxRegistry.songsByCategory(cat);
    } else {
      songs = JukeboxRegistry.allSongs.toList();
    }

    if (songs.isEmpty) return;

    // Set soundfont if specified
    if (widget.config.musicSoundFontId != null) {
      final sf = JukeboxRegistry.findSoundFontById(widget.config.musicSoundFontId!);
      if (sf != null) jukebox.setSoundFont(sf);
    }

    // Set volume
    jukebox.setVolume(widget.config.musicVolume);

    // Play
    jukebox.playQueue(songs, shuffleQueue: true);
  }

  void _stopMusic() {
    if (!mounted) return;
    final jukebox = context.read<JukeboxNotifier>();
    jukebox.stop();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _hideControlsTimer?.cancel();
    _kenBurnsController.dispose();
    _manualZoomController.dispose();
    _focusNode.dispose();
    _stopMusic();
    super.dispose();
  }

  void _startKenBurns() {
    if (!widget.config.kenBurnsEnabled || widget.config.manualZoomEnabled) {
      return;
    }
    _kenBurns = KenBurnsAnimation.random(widget.config.kenBurnsIntensity);
    _kenBurnsController
      ..reset()
      ..duration = Duration(
          milliseconds: (widget.config.slideDuration * 1000).round())
      ..forward();
  }

  void _scheduleSlide() {
    _slideTimer?.cancel();
    if (!_isPlaying) return;
    _slideTimer = Timer(
      Duration(milliseconds: (widget.config.slideDuration * 1000).round()),
      _goNext,
    );
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _showControlsAndReset() {
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  void _goNext() {
    if (!mounted || widget.playlist.isEmpty) return;
    int next = _currentIndex;
    for (int i = 0; i < widget.playlist.length; i++) {
      next++;
      if (next >= widget.playlist.length) {
        if (widget.config.loopEnabled) {
          next = 0;
        } else {
          setState(() => _isPlaying = false);
          return;
        }
      }
      if (widget.playlist[next].file.existsSync()) {
        setState(() => _currentIndex = next);
        _manualZoomController.value = Matrix4.identity();
        _startKenBurns();
        _scheduleSlide();
        _preloadNext();
        return;
      }
    }
    // All files deleted — stop playback
    setState(() => _isPlaying = false);
  }

  void _goPrev() {
    if (!mounted || widget.playlist.isEmpty) return;
    int prev = _currentIndex - 1;
    if (prev < 0) {
      prev = widget.config.loopEnabled ? widget.playlist.length - 1 : 0;
    }
    setState(() => _currentIndex = prev);
    _manualZoomController.value = Matrix4.identity();
    _startKenBurns();
    _scheduleSlide();
    _preloadNext();
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _scheduleSlide();
    } else {
      _slideTimer?.cancel();
    }
  }

  void _preloadNext() {
    if (!mounted) return;
    int next = _currentIndex + 1;
    if (next >= widget.playlist.length) {
      next = widget.config.loopEnabled ? 0 : _currentIndex;
    }
    if (next < widget.playlist.length) {
      _nextImageProvider = FileImage(widget.playlist[next].file);
      // Warm up the image cache
      if (mounted) {
        precacheImage(_nextImageProvider!, context).catchError((_) {});
      }
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        _goNext();
        _showControlsAndReset();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _goPrev();
        _showControlsAndReset();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.space:
        _togglePlayPause();
        _showControlsAndReset();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        Navigator.pop(context);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyM:
        // Toggle music mute
        if (widget.config.musicEnabled) {
          setState(() => _musicMuted = !_musicMuted);
          final jukebox = context.read<JukeboxNotifier>();
          jukebox.toggleMute();
          _showControlsAndReset();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyK:
        // Toggle karaoke overlay
        setState(() => _showKaraoke = !_showKaraoke);
        _showControlsAndReset();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    if (widget.playlist.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library_outlined,
                  color: Colors.white24, size: 48),
              const SizedBox(height: 16),
              Text(l.slideshowNoImages,
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                      letterSpacing: 2)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.slideshowGoBack,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 1)),
              ),
            ],
          ),
        ),
      );
    }

    final item = widget.playlist[_currentIndex];
    final imageWidget = Image.file(
      item.file,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      key: ValueKey(item.basename),
    );

    Widget display;
    if (widget.config.manualZoomEnabled) {
      display = GestureDetector(
        onDoubleTap: () => _manualZoomController.value = Matrix4.identity(),
        child: InteractiveViewer(
          transformationController: _manualZoomController,
          minScale: 1.0,
          maxScale: 5.0,
          child: Center(child: imageWidget),
        ),
      );
    } else if (widget.config.kenBurnsEnabled && _kenBurns != null) {
      display = AnimatedBuilder(
        animation: _kenBurnsController,
        builder: (context, child) {
          final t = _kenBurnsController.value;
          final scale = _kenBurns!.scaleAt(t);
          final offset = _kenBurns!.offsetAt(t);
          return ClipRect(
            child: Transform.scale(
              scale: scale,
              child: Transform.translate(
                offset: Offset(
                  offset.dx * MediaQuery.of(context).size.width,
                  offset.dy * MediaQuery.of(context).size.height,
                ),
                child: Center(child: child),
              ),
            ),
          );
        },
        child: imageWidget,
      );
    } else {
      display = Center(child: imageWidget);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: MouseRegion(
          onHover: (_) => _showControlsAndReset(),
          child: GestureDetector(
            onTap: _showControlsAndReset,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image with transition
                AnimatedSwitcher(
                  duration: Duration(
                      milliseconds:
                          (widget.config.transitionDuration * 1000).round()),
                  transitionBuilder:
                      SlideshowAnimationService.getTransitionBuilder(
                          widget.config.transition),
                  child: SizedBox.expand(
                    key: ValueKey(_currentIndex),
                    child: display,
                  ),
                ),

                // Karaoke overlay
                if (_showKaraoke && widget.config.musicEnabled)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 80,
                    child: KaraokeOverlay(),
                  ),

                // Controls overlay
                if (_showControls) ...[
                  // Top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_currentIndex + 1} / ${widget.playlist.length}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                letterSpacing: 1),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.music_note,
                                    color: Colors.white70, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog.fullscreen(
                                      backgroundColor: Colors.black,
                                      child: Scaffold(
                                        backgroundColor: Colors.black,
                                        appBar: AppBar(
                                          backgroundColor: Colors.black,
                                          leading: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white70),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                        body: const JukeboxPanel(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white70, size: 24),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                        top: 16,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous,
                                color: Colors.white70, size: 32),
                            onPressed: _goPrev,
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                                size: 48),
                            onPressed: _togglePlayPause,
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            icon: const Icon(Icons.skip_next,
                                color: Colors.white70, size: 32),
                            onPressed: _goNext,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
