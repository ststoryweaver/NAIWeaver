import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../novel_ai_service.dart';
import '../../vibe_transfer/providers/vibe_transfer_notifier.dart';
import '../../vibe_transfer/widgets/vibe_transfer_chip.dart';
import '../../vibe_transfer/widgets/vibe_transfer_editor_sheet.dart';

class VibeTransferShelf extends StatelessWidget {
  const VibeTransferShelf({super.key});

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API key missing or invalid')),
              );
            }
            return;
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to encode vibe image')),
              );
            }
            return;
          }
        }
      }
    }
  }

  void _openEditor(BuildContext context, VibeTransferNotifier notifier, vibeTransfer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VibeTransferEditorSheet(
        vibe: vibeTransfer,
        onStrengthChanged: (v) => notifier.updateStrength(vibeTransfer.id, v),
        onInfoExtractedChanged: (v) => notifier.updateInfoExtracted(vibeTransfer.id, v),
        onRemove: () => notifier.removeVibe(vibeTransfer.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VibeTransferNotifier>(
      builder: (context, notifier, _) {
        final vibes = notifier.vibes;
        final mobile = isMobile(context);

        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: mobile ? 52 : 44,
            margin: const EdgeInsets.only(top: 2, bottom: 2),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...vibes.map((vibe) => VibeTransferChip(
                      vibe: vibe,
                      onTap: () => _openEditor(context, notifier, vibe),
                      onLongPress: () => notifier.removeVibe(vibe.id),
                    )),
                _AddVibeButton(
                  isProcessing: notifier.isProcessing,
                  onTap: () => _pickAndAdd(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddVibeButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isProcessing;

  const _AddVibeButton({required this.onTap, this.isProcessing = false});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final mobile = isMobile(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: isProcessing ? null : onTap,
        child: Container(
          width: mobile ? 44 : 36,
          height: mobile ? 44 : 36,
          decoration: BoxDecoration(
            color: t.textMinimal,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: t.accentVibeTransfer.withValues(alpha: 0.3),
                width: 0.5),
          ),
          child: Center(
            child: isProcessing
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: t.accentVibeTransfer.withValues(alpha: 0.5),
                    ),
                  )
                : Icon(Icons.add_photo_alternate,
                    size: 14, color: t.accentVibeTransfer.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}
