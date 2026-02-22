import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jukebox_notifier.dart';
import '../../theme/theme_extensions.dart';
import 'karaoke_overlay.dart';
import 'karaoke_visualizer.dart';

class FullscreenVisualizer extends StatelessWidget {
  const FullscreenVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    final jukebox = context.watch<JukeboxNotifier>();
    final t = context.t;
    final song = jukebox.currentSong;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: KaraokeVisualizer()),
          const Positioned.fill(
            child: Center(child: KaraokeOverlay()),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Transport controls at bottom
          if (song != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: t.fontSize(10),
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (song.artist != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        song.artist!.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: t.fontSize(8),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 28),
                        onPressed: jukebox.previous,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          jukebox.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: jukebox.isPlaying ? jukebox.pause : jukebox.resume,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white70, size: 28),
                        onPressed: jukebox.next,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
