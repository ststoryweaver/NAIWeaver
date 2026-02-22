import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/path_service.dart';
import '../../../core/services/reference_library_service.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/vision_slider.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/services/novel_ai_service.dart';
import '../models/vibe_transfer.dart';
import '../providers/vibe_transfer_notifier.dart';

class VibeTransferManager extends StatefulWidget {
  const VibeTransferManager({super.key});

  @override
  State<VibeTransferManager> createState() => _VibeTransferManagerState();
}

class _VibeTransferManagerState extends State<VibeTransferManager> {
  List<SavedVibeTransfer> _savedVibes = [];
  bool _libraryLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  String get _libraryPath =>
      context.read<PathService>().referenceLibraryFilePath;

  Future<void> _loadLibrary() async {
    final library = await ReferenceLibraryService.load(_libraryPath);
    if (mounted) {
      setState(() {
        _savedVibes = library.vibeTransfers;
        _libraryLoaded = true;
      });
    }
  }

  Future<void> _saveToLibrary(VibeTransfer vibe) async {
    final name = await _promptForName(context, context.l.refSaveVibe);
    if (name == null || name.isEmpty) return;

    final saved = SavedVibeTransfer(
      name: name,
      vibe: vibe,
      savedAt: DateTime.now(),
    );

    final library = await ReferenceLibraryService.load(_libraryPath);
    library.vibeTransfers = [...library.vibeTransfers, saved];
    await ReferenceLibraryService.save(_libraryPath, library);
    setState(() => _savedVibes = library.vibeTransfers);
  }

  Future<void> _deleteSaved(int index) async {
    final library = await ReferenceLibraryService.load(_libraryPath);
    library.vibeTransfers = List.from(library.vibeTransfers)..removeAt(index);
    await ReferenceLibraryService.save(_libraryPath, library);
    setState(() => _savedVibes = library.vibeTransfers);
  }

  void _loadSaved(SavedVibeTransfer saved) {
    final notifier = context.read<VibeTransferNotifier>();
    // Vector is already stored, no API call needed
    final vibes = List<VibeTransfer>.from(notifier.vibes)..add(saved.vibe);
    notifier.setVibes(vibes);
  }

  Future<String?> _promptForName(BuildContext context, String title) async {
    final controller = TextEditingController();
    final t = context.t;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(title,
            style: TextStyle(
                fontSize: t.fontSize(10),
                letterSpacing: 2,
                color: t.textSecondary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
          decoration: InputDecoration(
            hintText: context.l.refNameHint,
            hintStyle:
                TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: t.borderMedium)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l.refDialogCancel,
                style: TextStyle(
                    color: t.textDisabled, fontSize: t.fontSize(9))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(context.l.refDialogSave,
                style: TextStyle(
                    color: t.textPrimary, fontSize: t.fontSize(9))),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndAdd(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null && context.mounted) {
      final notifier = context.read<VibeTransferNotifier>();
      for (final file in result.files) {
        if (file.path != null) {
          final bytes = await File(file.path!).readAsBytes();
          if (!context.mounted) return;
          try {
            await notifier.addVibe(bytes);
          } on UnauthorizedException {
            if (context.mounted) {
              showErrorSnackBar(context, context.l.refApiKeyMissing);
            }
            return;
          } catch (e) {
            if (context.mounted) {
              showErrorSnackBar(context, context.l.refVibeEncodeFailed(e.toString()));
            }
            return;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Consumer<VibeTransferNotifier>(
      builder: (context, notifier, _) {
        final vibes = notifier.vibes;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l.refVibeTransfers,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: t.fontSize(12),
                      letterSpacing: 4,
                      color: t.textPrimary,
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (vibes.isNotEmpty)
                          TextButton(
                            onPressed: notifier.clearAll,
                            child: Text(
                              context.l.refClearAll,
                              style: TextStyle(
                                color: t.accentDanger,
                                fontSize: t.fontSize(9),
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            context.l.refVibeCount(vibes.length),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.textDisabled,
                              fontSize: t.fontSize(9),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: t.textMinimal),

            // Vibe list
            Expanded(
              child: vibes.isEmpty && _savedVibes.isEmpty
                  ? _buildEmptyState(context)
                  : _buildList(context, notifier, vibes),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final t = context.t;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_outlined, size: 48, color: t.textMinimal),
          const SizedBox(height: 16),
          Text(
            context.l.refNoVibesAdded,
            style: TextStyle(
              color: t.textDisabled,
              fontSize: t.fontSize(10),
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l.refVibeEmptyDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: t.textMinimal, fontSize: t.fontSize(11), height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _pickAndAdd(context),
            icon: const Icon(Icons.add_photo_alternate, size: 14),
            label: Text(
              context.l.refAddVibe,
              style: TextStyle(
                  fontSize: t.fontSize(9),
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.background,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, VibeTransferNotifier notifier,
      List<VibeTransfer> vibes) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          ...vibes.map((vibe) => _VibeCard(
                vibe: vibe,
                onStrengthChanged: (v) =>
                    notifier.updateStrength(vibe.id, v),
                onInfoExtractedChanged: (v) =>
                    notifier.updateInfoExtracted(vibe.id, v),
                onRemove: () => notifier.removeVibe(vibe.id),
                onSave: () => _saveToLibrary(vibe),
              )),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _pickAndAdd(context),
              icon: const Icon(Icons.add_photo_alternate, size: 14),
              label: Text(
                context.l.refAddVibe,
                style: TextStyle(
                    fontSize: t.fontSize(9),
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.textMinimal,
                foregroundColor: t.textSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
            ),
          ),

          // Saved Library Section
          if (_libraryLoaded && _savedVibes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(height: 1, color: t.textMinimal),
            const SizedBox(height: 16),
            Text(
              context.l.refSavedSection,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: t.fontSize(10),
                letterSpacing: 3,
                color: t.textDisabled,
              ),
            ),
            const SizedBox(height: 12),
            ..._savedVibes.asMap().entries.map((entry) {
              final idx = entry.key;
              final saved = entry.value;
              return _SavedVibeCard(
                saved: saved,
                onLoad: () => _loadSaved(saved),
                onDelete: () => _deleteSaved(idx),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _VibeCard extends StatelessWidget {
  final VibeTransfer vibe;
  final Function(double) onStrengthChanged;
  final Function(double) onInfoExtractedChanged;
  final VoidCallback onRemove;
  final VoidCallback onSave;

  const _VibeCard({
    required this.vibe,
    required this.onStrengthChanged,
    required this.onInfoExtractedChanged,
    required this.onRemove,
    required this.onSave,
  });

  static const _vibeGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    final thumbSize = mobile ? 64.0 : 80.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.borderSubtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: _vibeGreen.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _vibeGreen, width: 1),
              image: DecorationImage(
                image: MemoryImage(vibe.originalImageBytes),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + save + remove
                Row(
                  children: [
                    Text(
                      context.l.refVibeLabel,
                      style: TextStyle(
                        fontSize: t.fontSize(8),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: _vibeGreen,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onSave,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.bookmark_border,
                            size: 14, color: t.textDisabled),
                      ),
                    ),
                    GestureDetector(
                      onTap: onRemove,
                      child: Icon(Icons.close,
                          size: 14, color: t.textDisabled),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Strength
                _InlineSlider(
                  label: context.l.refStrengthShort,
                  value: vibe.strength,
                  color: _vibeGreen,
                  onChanged: onStrengthChanged,
                ),
                const SizedBox(height: 6),

                // Info Extracted
                _InlineSlider(
                  label: context.l.refInfoExtractedShort,
                  value: vibe.infoExtracted,
                  color: _vibeGreen,
                  onChanged: onInfoExtractedChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedVibeCard extends StatelessWidget {
  final SavedVibeTransfer saved;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _SavedVibeCard({
    required this.saved,
    required this.onLoad,
    required this.onDelete,
  });

  static const _vibeGreen = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    final thumbSize = mobile ? 48.0 : 56.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.borderSubtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: t.textMinimal, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _vibeGreen.withValues(alpha: 0.5), width: 0.5),
              image: DecorationImage(
                image: MemoryImage(saved.vibe.originalImageBytes),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saved.name,
                  style: TextStyle(
                    fontSize: t.fontSize(10),
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.l.refStrengthShort} ${saved.vibe.strength.toStringAsFixed(2)}  ${context.l.refInfoExtractedShort} ${saved.vibe.infoExtracted.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: t.fontSize(8),
                    color: t.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onLoad,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.add_circle_outline,
                  size: 18, color: _vibeGreen),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.delete_outline,
                size: 16, color: t.accentDanger),
          ),
        ],
      ),
    );
  }
}

class _InlineSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _InlineSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(
              fontSize: t.fontSize(mobile ? 10 : 8),
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: t.textDisabled,
            ),
          ),
        ),
        Expanded(
          child: VisionSlider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 1.0,
            activeColor: color.withValues(alpha: 0.5),
            inactiveColor: t.textMinimal,
            thumbColor: color,
            thumbRadius: mobile ? 8 : 5,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: t.fontSize(9),
              color: t.textTertiary,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
      ],
    );
  }
}
