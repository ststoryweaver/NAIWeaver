import 'package:flutter/material.dart';
import '../../../../core/jukebox/models/jukebox_soundfont.dart';
import '../../../../core/jukebox/jukebox_registry.dart';
import '../../../../core/jukebox/providers/jukebox_notifier.dart';
import '../../../../core/services/download_manager.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../core/widgets/confirm_dialog.dart';

/// SoundFont selection list with download / delete / progress UI.
class JukeboxSoundFontPicker extends StatelessWidget {
  final JukeboxNotifier jukebox;
  final VisionTokens t;

  const JukeboxSoundFontPicker({super.key, required this.jukebox, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: JukeboxRegistry.allSoundFonts.map((sf) {
        final selected = jukebox.activeSoundFont.id == sf.id;
        final available = jukebox.isSoundFontAvailable(sf);
        final dlState = jukebox.sfDownloadState(sf.id);
        final isDownloading = dlState.status == DownloadStatus.downloading;
        final isError = dlState.status == DownloadStatus.error;
        final isDownloaded = jukebox.isSoundFontAvailable(sf) && !sf.isBundled;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: selected ? t.accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? t.accent : t.borderSubtle,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: available ? () => jukebox.setSoundFont(sf) : null,
                child: Row(
                  children: [
                    if (sf.isGag)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.sentiment_very_satisfied, size: 14, color: t.accent),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sf.name.toUpperCase(),
                              style: TextStyle(
                                  color: available
                                      ? (selected ? t.accent : t.textSecondary)
                                      : t.textDisabled,
                                  fontSize: t.fontSize(9),
                                  letterSpacing: 1,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                          Text(sf.description,
                              style: TextStyle(
                                  color: t.textMinimal,
                                  fontSize: t.fontSize(7),
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    // Status badges & actions
                    ..._buildTrailingActions(context, sf,
                        selected: selected,
                        isDownloading: isDownloading,
                        isError: isError,
                        isDownloaded: isDownloaded),
                  ],
                ),
              ),
              // Progress bar during download
              if (isDownloading) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: dlState.progress,
                          backgroundColor: t.borderSubtle,
                          valueColor: AlwaysStoppedAnimation<Color>(t.accent),
                          minHeight: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(dlState.progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: t.textMinimal,
                            fontSize: t.fontSize(7))),
                  ],
                ),
              ],
              // Error message
              if (isError && dlState.errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(dlState.errorMessage!,
                    style: TextStyle(
                        color: t.accentDanger,
                        fontSize: t.fontSize(7))),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildTrailingActions(
    BuildContext context,
    JukeboxSoundFont sf, {
    required bool selected,
    required bool isDownloading,
    required bool isError,
    required bool isDownloaded,
  }) {
    if (sf.isBundled && !sf.isDownloadable) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: t.borderSubtle,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text('BUNDLED',
              style: TextStyle(
                  color: t.textMinimal,
                  fontSize: t.fontSize(6),
                  letterSpacing: 0.5)),
        ),
        if (selected)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(Icons.check, size: 14, color: t.accent),
          ),
      ];
    }

    if (isDownloading) {
      return [
        InkWell(
          onTap: () => jukebox.cancelSoundFontDownload(sf.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text('CANCEL',
                style: TextStyle(
                    color: t.accent,
                    fontSize: t.fontSize(7),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ),
        ),
      ];
    }

    if (isError) {
      return [
        InkWell(
          onTap: () => jukebox.downloadSoundFont(sf),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text('RETRY',
                style: TextStyle(
                    color: t.accent,
                    fontSize: t.fontSize(7),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ),
        ),
      ];
    }

    if (isDownloaded) {
      return [
        if (selected)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.check, size: 14, color: t.accent),
          ),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 14, color: t.textMinimal),
          onPressed: () => _confirmDeleteSoundFont(context, sf),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
          tooltip: 'Delete soundfont',
        ),
      ];
    }

    // Not downloaded -- show download button
    return [
      Text(sf.fileSizeLabel,
          style: TextStyle(
              color: t.textMinimal,
              fontSize: t.fontSize(7))),
      const SizedBox(width: 6),
      InkWell(
        onTap: () => jukebox.downloadSoundFont(sf),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text('DOWNLOAD',
              style: TextStyle(
                  color: t.accent,
                  fontSize: t.fontSize(7),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ),
      ),
      if (selected && sf.isBundled)
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Icon(Icons.check, size: 14, color: t.accent),
        ),
    ];
  }

  Future<void> _confirmDeleteSoundFont(BuildContext context, JukeboxSoundFont sf) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'DELETE SOUNDFONT',
      message: 'Delete ${sf.name}? You can re-download it later.',
      confirmLabel: 'DELETE',
      confirmColor: t.accentDanger,
    );
    if (confirm == true) {
      jukebox.deleteSoundFont(sf);
    }
  }
}
