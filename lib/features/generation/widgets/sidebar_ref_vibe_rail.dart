import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/model_gate.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/file_picker_helper.dart';
import '../../../core/services/novel_ai_service.dart';
import '../../director_ref/models/director_reference.dart';
import '../../director_ref/providers/director_ref_notifier.dart';
import '../../director_ref/widgets/director_ref_editor_sheet.dart';
import '../../director_ref/widgets/director_ref_shelf.dart' show SavedRefsSheet;
import '../../vibe_transfer/providers/vibe_transfer_notifier.dart';
import '../../vibe_transfer/widgets/vibe_transfer_editor_sheet.dart';

/// Vertical rail of REF/VIBE thumbnails for sidebar mode.
/// Positioned on the right edge of the image viewer area.
class SidebarRefVibeRail extends StatelessWidget {
  final bool showRef;
  final bool showVibe;

  const SidebarRefVibeRail({
    super.key,
    required this.showRef,
    required this.showVibe,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: t.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showRef) _RefSection(t: t),
          if (showRef && showVibe) SizedBox(height: 8, child: Divider(color: t.borderSubtle, indent: 8, endIndent: 8)),
          if (showVibe) _VibeSection(t: t),
        ],
      ),
    );
  }
}

class _RefSection extends StatelessWidget {
  final VisionTokens t;
  const _RefSection({required this.t});

  Future<void> _pickAndAdd(BuildContext context, {bool useFileBrowser = false}) async {
    final result = await pickImageFiles(useFileBrowser: useFileBrowser);
    if (result != null && result.files.single.path != null) {
      final bytes = await File(result.files.single.path!).readAsBytes();
      if (context.mounted) {
        context.read<DirectorRefNotifier>().addReference(bytes);
      }
    }
  }

  Future<void> _showRefMenu(BuildContext context) async {
    final menuT = context.t;
    final l = context.l;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final value = await showMenu<String>(
      context: context,
      position: position,
      color: menuT.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      items: [
        PopupMenuItem(
          value: 'library',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_outline, size: 14, color: menuT.accentRefCharacter),
              const SizedBox(width: 8),
              Text(l.refLoadSaved, style: TextStyle(
                fontSize: menuT.fontSize(9),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: menuT.textPrimary,
              )),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pick',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 14, color: menuT.accentRefCharacter),
              const SizedBox(width: 8),
              Text(l.refPickImage, style: TextStyle(
                fontSize: menuT.fontSize(9),
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: menuT.textPrimary,
              )),
            ],
          ),
        ),
        if (!kIsWeb && Platform.isAndroid)
          PopupMenuItem(
            value: 'browse',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, size: 14, color: menuT.accentRefCharacter),
                const SizedBox(width: 8),
                Text(l.refBrowseFiles, style: TextStyle(
                  fontSize: menuT.fontSize(9),
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                  color: menuT.textPrimary,
                )),
              ],
            ),
          ),
      ],
    );
    if (!context.mounted) return;
    if (value == 'library') {
      _showSavedRefsSheet(context);
    } else if (value == 'pick') {
      _pickAndAdd(context);
    } else if (value == 'browse') {
      _pickAndAdd(context, useFileBrowser: true);
    }
  }

  void _showSavedRefsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavedRefsSheet(
        onLoad: (saved) async {
          final notifier = context.read<DirectorRefNotifier>();
          await notifier.addReference(saved.reference.originalImageBytes);
          final refs = notifier.references;
          if (refs.isNotEmpty) {
            final last = refs.last;
            notifier.updateType(last.id, saved.reference.type);
            notifier.updateStrength(last.id, saved.reference.strength);
            notifier.updateFidelity(last.id, saved.reference.fidelity);
          }
        },
        onPickImage: () => _pickAndAdd(context),
        onBrowseFiles: !kIsWeb && Platform.isAndroid
            ? () => _pickAndAdd(context, useFileBrowser: true)
            : null,
      ),
    );
  }

  void _openEditor(BuildContext context, DirectorRefNotifier notifier, DirectorReference ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DirectorRefEditorSheet(
        reference: ref,
        onTypeChanged: (v) => notifier.updateType(ref.id, v),
        onStrengthChanged: (v) => notifier.updateStrength(ref.id, v),
        onFidelityChanged: (v) => notifier.updateFidelity(ref.id, v),
        onToggleEnabled: () => notifier.toggleEnabled(ref.id),
        onRemove: () => notifier.removeReference(ref.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DirectorRefNotifier>(
      builder: (context, notifier, _) {
        final refs = notifier.references;
        return ModelGate(
          capability: (caps) => caps.characterReference,
          feature: 'Character Reference',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...refs.map((ref) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _RailChip(
                  imageBytes: ref.originalImageBytes,
                  borderColor: _refBorderColor(ref.type, t),
                  icon: _refIcon(ref.type),
                  enabled: ref.enabled,
                  onTap: () => _openEditor(context, notifier, ref),
                  onLongPress: () => notifier.removeReference(ref.id),
                ),
              )),
              _RailAddButton(
                label: 'REF',
                color: t.accentRefCharacter,
                isProcessing: notifier.isProcessing,
                onTap: () => _showSavedRefsSheet(context),
                onLongPress: () => _showRefMenu(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _refBorderColor(DirectorReferenceType type, VisionTokens t) {
    switch (type) {
      case DirectorReferenceType.character:
        return t.accentRefCharacter;
      case DirectorReferenceType.style:
        return t.accentRefStyle;
      case DirectorReferenceType.characterAndStyle:
        return t.accentRefCharStyle;
    }
  }

  IconData _refIcon(DirectorReferenceType type) {
    switch (type) {
      case DirectorReferenceType.character:
        return Icons.person;
      case DirectorReferenceType.style:
        return Icons.palette;
      case DirectorReferenceType.characterAndStyle:
        return Icons.auto_awesome;
    }
  }
}

class _VibeSection extends StatelessWidget {
  final VisionTokens t;
  const _VibeSection({required this.t});

  Future<void> _pickAndAdd(BuildContext context) async {
    final result = await pickImageFiles(allowMultiple: true);
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
              showErrorSnackBar(context, 'API key missing or invalid');
            }
            return;
          } catch (e) {
            if (context.mounted) {
              showErrorSnackBar(context, 'Failed to encode vibe image');
            }
            return;
          }
        }
      }
    }
  }

  void _openEditor(BuildContext context, VibeTransferNotifier notifier, vibe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VibeTransferEditorSheet(
        vibe: vibe,
        onStrengthChanged: (v) => notifier.updateStrength(vibe.id, v),
        onInfoExtractedChanged: (v) => notifier.updateInfoExtracted(vibe.id, v),
        onToggleEnabled: () => notifier.toggleEnabled(vibe.id),
        onRemove: () => notifier.removeVibe(vibe.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VibeTransferNotifier>(
      builder: (context, notifier, _) {
        final vibes = notifier.vibes;
        return ModelGate(
          capability: (caps) => caps.vibeTransfer,
          feature: 'Vibe Transfer',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...vibes.map((vibe) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _RailChip(
                  imageBytes: vibe.originalImageBytes,
                  borderColor: t.accent,
                  enabled: vibe.enabled,
                  onTap: () => _openEditor(context, notifier, vibe),
                  onLongPress: () => notifier.removeVibe(vibe.id),
                ),
              )),
              _RailAddButton(
                label: 'VIBE',
                color: t.accent,
                isProcessing: notifier.isProcessing,
                onTap: () => _pickAndAdd(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Small image thumbnail for the vertical rail.
class _RailChip extends StatelessWidget {
  final dynamic imageBytes;
  final Color borderColor;
  final IconData? icon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RailChip({
    required this.imageBytes,
    required this.borderColor,
    this.icon,
    this.enabled = true,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final disabled = !enabled;
    final border = disabled ? t.textDisabled : borderColor;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: 1.5),
            image: DecorationImage(
              image: MemoryImage(imageBytes),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              colorFilter: disabled
                  ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                  : null,
            ),
          ),
          child: (icon != null || disabled)
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: t.background.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(3)),
                    ),
                    child: Icon(
                      disabled ? Icons.visibility_off : icon,
                      size: 10,
                      color: border,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Small labeled add button for the vertical rail.
class _RailAddButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isProcessing;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _RailAddButton({
    required this.label,
    required this.color,
    required this.isProcessing,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      onLongPress: isProcessing ? null : onLongPress,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProcessing)
              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: color))
            else
              Icon(Icons.add, size: 14, color: color),
            Text(
              label,
              style: TextStyle(
                fontSize: t.fontSize(6),
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
