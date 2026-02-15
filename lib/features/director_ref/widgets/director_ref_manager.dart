import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/path_service.dart';
import '../../../core/services/reference_library_service.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../models/director_reference.dart';
import '../providers/director_ref_notifier.dart';

class DirectorRefManager extends StatefulWidget {
  const DirectorRefManager({super.key});

  @override
  State<DirectorRefManager> createState() => _DirectorRefManagerState();
}

class _DirectorRefManagerState extends State<DirectorRefManager> {
  List<SavedDirectorRef> _savedRefs = [];
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
        _savedRefs = library.directorRefs;
        _libraryLoaded = true;
      });
    }
  }

  Future<void> _saveToLibrary(DirectorReference ref) async {
    final name = await _promptForName(context, context.l.refSaveReference);
    if (name == null || name.isEmpty) return;

    final saved = SavedDirectorRef(
      name: name,
      reference: ref,
      savedAt: DateTime.now(),
    );

    final library = await ReferenceLibraryService.load(_libraryPath);
    library.directorRefs = [...library.directorRefs, saved];
    await ReferenceLibraryService.save(_libraryPath, library);
    setState(() => _savedRefs = library.directorRefs);
  }

  Future<void> _deleteSaved(int index) async {
    final library = await ReferenceLibraryService.load(_libraryPath);
    library.directorRefs = List.from(library.directorRefs)..removeAt(index);
    await ReferenceLibraryService.save(_libraryPath, library);
    setState(() => _savedRefs = library.directorRefs);
  }

  Future<void> _loadSaved(SavedDirectorRef saved) async {
    final notifier = context.read<DirectorRefNotifier>();
    await notifier.addReference(saved.reference.originalImageBytes);
    // Update the newly-added reference with saved settings
    final refs = notifier.references;
    if (refs.isNotEmpty) {
      final last = refs.last;
      notifier.updateType(last.id, saved.reference.type);
      notifier.updateStrength(last.id, saved.reference.strength);
      notifier.updateFidelity(last.id, saved.reference.fidelity);
    }
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
      final notifier = context.read<DirectorRefNotifier>();
      for (final file in result.files) {
        if (file.path != null) {
          final bytes = await File(file.path!).readAsBytes();
          if (context.mounted) {
            await notifier.addReference(bytes);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Consumer<DirectorRefNotifier>(
      builder: (context, notifier, _) {
        final refs = notifier.references;

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
                    context.l.refPreciseReferences,
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
                        if (refs.isNotEmpty)
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
                            context.l.refReferenceCount(refs.length),
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

            // Reference grid
            Expanded(
              child: refs.isEmpty && _savedRefs.isEmpty
                  ? _buildEmptyState(context)
                  : _buildGrid(context, notifier, refs),
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
          Icon(Icons.photo_library_outlined, size: 48, color: t.textMinimal),
          const SizedBox(height: 16),
          Text(
            context.l.refNoReferencesAdded,
            style: TextStyle(
              color: t.textDisabled,
              fontSize: t.fontSize(10),
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l.refEmptyDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: t.textMinimal, fontSize: t.fontSize(11), height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _pickAndAdd(context),
            icon: const Icon(Icons.add_photo_alternate, size: 14),
            label: Text(
              context.l.refAddReference,
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

  Widget _buildGrid(BuildContext context, DirectorRefNotifier notifier,
      List<DirectorReference> refs) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          ...refs.map((ref) => _ReferenceCard(
                reference: ref,
                onTypeChanged: (t) => notifier.updateType(ref.id, t),
                onStrengthChanged: (v) => notifier.updateStrength(ref.id, v),
                onFidelityChanged: (v) => notifier.updateFidelity(ref.id, v),
                onRemove: () => notifier.removeReference(ref.id),
                onSave: () => _saveToLibrary(ref),
              )),
          const SizedBox(height: 16),
          // Add button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _pickAndAdd(context),
              icon: const Icon(Icons.add_photo_alternate, size: 14),
              label: Text(
                context.l.refAddReference,
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
          if (_libraryLoaded && _savedRefs.isNotEmpty) ...[
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
            ..._savedRefs.asMap().entries.map((entry) {
              final idx = entry.key;
              final saved = entry.value;
              return _SavedRefCard(
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

String _localizedRefType(BuildContext context, DirectorReferenceType type) {
  final l = context.l;
  switch (type) {
    case DirectorReferenceType.character:
      return l.refTypeCharacter;
    case DirectorReferenceType.style:
      return l.refTypeStyle;
    case DirectorReferenceType.characterAndStyle:
      return l.refTypeCharAndStyle;
  }
}

class _ReferenceCard extends StatelessWidget {
  final DirectorReference reference;
  final Function(DirectorReferenceType) onTypeChanged;
  final Function(double) onStrengthChanged;
  final Function(double) onFidelityChanged;
  final VoidCallback onRemove;
  final VoidCallback onSave;

  const _ReferenceCard({
    required this.reference,
    required this.onTypeChanged,
    required this.onStrengthChanged,
    required this.onFidelityChanged,
    required this.onRemove,
    required this.onSave,
  });

  Color _colorForType(DirectorReferenceType type) {
    switch (type) {
      case DirectorReferenceType.character:
        return Colors.cyanAccent;
      case DirectorReferenceType.style:
        return const Color(0xFFFF00FF);
      case DirectorReferenceType.characterAndStyle:
        return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = _colorForType(reference.type);
    final mobile = isMobile(context);
    final thumbSize = mobile ? 64.0 : 80.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.borderSubtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
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
              border: Border.all(color: color, width: 1),
              image: DecorationImage(
                image: MemoryImage(reference.originalImageBytes),
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
                // Type selector + save + remove button
                Row(
                  children: [
                    ...DirectorReferenceType.values.map((refType) {
                      final isSelected = reference.type == refType;
                      final c = _colorForType(refType);
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () => onTypeChanged(refType),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: mobile ? 6 : 8,
                                vertical: mobile ? 6 : 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? c.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: isSelected ? c : t.textMinimal,
                                width: isSelected ? 1 : 0.5,
                              ),
                            ),
                            child: Text(
                              _localizedRefType(context, refType),
                              style: TextStyle(
                                fontSize: t.fontSize(7),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: isSelected ? c : t.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
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
                      child: Padding(
                        padding: const EdgeInsets.only(left: 1),
                        child:
                            Icon(Icons.close, size: 14, color: t.textDisabled),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Strength
                _InlineSlider(
                  label: context.l.refStrengthShort,
                  value: reference.strength,
                  color: color,
                  onChanged: onStrengthChanged,
                ),
                const SizedBox(height: 6),

                // Fidelity
                _InlineSlider(
                  label: context.l.refFidelityShort,
                  value: reference.fidelity,
                  color: color,
                  onChanged: onFidelityChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedRefCard extends StatelessWidget {
  final SavedDirectorRef saved;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _SavedRefCard({
    required this.saved,
    required this.onLoad,
    required this.onDelete,
  });

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
              border: Border.all(color: t.textMinimal, width: 0.5),
              image: DecorationImage(
                image: MemoryImage(saved.reference.originalImageBytes),
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
                  '${_localizedRefType(context, saved.reference.type)}  ${context.l.refStrengthShort} ${saved.reference.strength.toStringAsFixed(2)}  ${context.l.refFidelityShort} ${saved.reference.fidelity.toStringAsFixed(2)}',
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
                  size: 18, color: t.accent),
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
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color.withValues(alpha: 0.5),
              inactiveTrackColor: t.textMinimal,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.1),
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: mobile ? 8 : 5),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
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
