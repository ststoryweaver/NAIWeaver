import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../models/director_reference.dart';
import '../providers/director_ref_notifier.dart';
import 'director_ref_chip.dart';
import 'director_ref_editor_sheet.dart';

class DirectorRefShelf extends StatelessWidget {
  const DirectorRefShelf({super.key});

  Future<void> _pickAndAdd(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      final bytes = await File(result.files.single.path!).readAsBytes();
      if (context.mounted) {
        context.read<DirectorRefNotifier>().addReference(bytes);
      }
    }
  }

  void _openEditor(BuildContext context, DirectorRefNotifier notifier, DirectorReference ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DirectorRefEditorSheet(
        reference: ref,
        onTypeChanged: (t) => notifier.updateType(ref.id, t),
        onStrengthChanged: (v) => notifier.updateStrength(ref.id, v),
        onFidelityChanged: (v) => notifier.updateFidelity(ref.id, v),
        onRemove: () => notifier.removeReference(ref.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DirectorRefNotifier>(
      builder: (context, notifier, _) {
        final refs = notifier.references;

        final mobile = isMobile(context);
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: mobile ? 52 : 44,
            margin: const EdgeInsets.only(top: 2, bottom: 2),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...refs.map((ref) => DirectorRefChip(
                  reference: ref,
                  onTap: () => _openEditor(context, notifier, ref),
                  onLongPress: () => notifier.removeReference(ref.id),
                )),
                _AddRefButton(
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

class _AddRefButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onTap;

  const _AddRefButton({required this.isProcessing, required this.onTap});

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
            border: Border.all(color: t.textMinimal, width: 0.5),
          ),
          child: Center(
            child: isProcessing
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: t.textDisabled),
                  )
                : Icon(Icons.add_photo_alternate, size: 14, color: t.textDisabled),
          ),
        ),
      ),
    );
  }
}
