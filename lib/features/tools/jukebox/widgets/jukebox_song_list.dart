import 'package:flutter/material.dart';
import '../../../../core/jukebox/models/jukebox_song.dart';
import '../../../../core/jukebox/jukebox_registry.dart';
import '../../../../core/jukebox/providers/jukebox_notifier.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import 'jukebox_now_playing.dart';

/// Category filter chip row for the song browser.
class JukeboxCategoryChips extends StatelessWidget {
  final SongCategory? selectedCategory;
  final ValueChanged<SongCategory?> onCategoryChanged;
  final VisionTokens t;

  const JukeboxCategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: t.surfaceMid,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(null, 'ALL'),
            ...SongCategory.values.map((cat) =>
                _chip(cat, JukeboxRegistry.categoryDisplayName(cat))),
          ],
        ),
      ),
    );
  }

  Widget _chip(SongCategory? cat, String label) {
    final selected = selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => onCategoryChanged(cat),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? t.accent.withValues(alpha: 0.15) : t.borderSubtle,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? t.accent : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? t.accent : t.textSecondary,
                  fontSize: t.fontSize(8),
                  letterSpacing: 1,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}

/// Scrollable list of songs with play and queue buttons.
class JukeboxSongList extends StatelessWidget {
  final JukeboxNotifier jukebox;
  final VisionTokens t;
  final List<JukeboxSong> songs;

  const JukeboxSongList({
    super.key,
    required this.jukebox,
    required this.t,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isCurrent = jukebox.currentSong?.id == song.id;
        final isCustom = song.category == SongCategory.custom;

        return InkWell(
          onTap: () => jukebox.playSong(song),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: isCurrent ? t.borderSubtle : Colors.transparent,
            child: Row(
              children: [
                if (isCurrent && jukebox.isPlaying)
                  Icon(Icons.equalizer, size: 14, color: t.accent)
                else
                  Icon(Icons.music_note, size: 14, color: t.textMinimal),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent ? t.textPrimary : t.textSecondary,
                          fontSize: t.fontSize(9),
                          letterSpacing: 1,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (song.artist != null)
                        Text(
                          song.artist!.toUpperCase(),
                          style: TextStyle(
                            color: t.textMinimal,
                            fontSize: t.fontSize(7),
                            letterSpacing: 1,
                          ),
                        ),
                    ],
                  ),
                ),
                if (song.isKaraoke)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text('KAR',
                        style: TextStyle(
                            color: t.accent,
                            fontSize: t.fontSize(6),
                            fontWeight: FontWeight.bold)),
                  ),
                if (song.durationSeconds != null)
                  Text(
                    JukeboxNowPlaying.formatDuration(Duration(seconds: song.durationSeconds!)),
                    style: TextStyle(
                      color: t.textMinimal,
                      fontSize: t.fontSize(8),
                    ),
                  ),
                const SizedBox(width: 4),
                if (isCustom)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 14, color: t.textMinimal),
                    onPressed: () => _confirmDeleteCustomSong(context, song),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    tooltip: 'Delete custom song',
                  ),
                IconButton(
                  icon: Icon(Icons.add, size: 14, color: t.textDisabled),
                  onPressed: () {
                    jukebox.addToQueue(song);
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  tooltip: 'Add to queue',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteCustomSong(BuildContext context, JukeboxSong song) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'DELETE SONG',
      message: 'Delete ${song.title}? This will remove the file from disk.',
      confirmLabel: 'DELETE',
      confirmColor: t.accentDanger,
    );
    if (confirm == true) {
      jukebox.deleteCustomSong(song.id);
    }
  }
}

/// Queue display with reorder and remove.
class JukeboxQueue extends StatelessWidget {
  final JukeboxNotifier jukebox;
  final VisionTokens t;

  const JukeboxQueue({super.key, required this.jukebox, required this.t});

  @override
  Widget build(BuildContext context) {
    if (jukebox.queue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('QUEUE IS EMPTY',
            style: TextStyle(
                color: t.textMinimal,
                fontSize: t.fontSize(8),
                letterSpacing: 1)),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jukebox.queue.length,
      onReorder: jukebox.reorderQueue,
      itemBuilder: (context, index) {
        final song = jukebox.queue[index];
        final isCurrent = jukebox.currentSong != null && song.id == jukebox.currentSong!.id;
        return ListTile(
          key: ValueKey('${song.id}_$index'),
          dense: true,
          leading: Icon(
            isCurrent ? Icons.equalizer : Icons.drag_handle,
            size: 14,
            color: isCurrent ? t.accent : t.textMinimal,
          ),
          title: Text(
            song.title.toUpperCase(),
            style: TextStyle(
              color: isCurrent ? t.accent : t.textSecondary,
              fontSize: t.fontSize(8),
              letterSpacing: 1,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.close, size: 12, color: t.textMinimal),
            onPressed: () => jukebox.removeFromQueue(index),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        );
      },
    );
  }
}

/// Return the filtered song list based on the selected category.
List<JukeboxSong> filteredSongs(JukeboxNotifier jukebox, SongCategory? selectedCategory) {
  if (selectedCategory != null) {
    if (selectedCategory == SongCategory.custom) {
      return jukebox.customSongs;
    }
    return JukeboxRegistry.songsByCategory(selectedCategory);
  }
  return jukebox.allSongs;
}
