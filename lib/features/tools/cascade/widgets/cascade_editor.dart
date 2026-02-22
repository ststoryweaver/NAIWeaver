import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/cascade_notifier.dart';
import 'cascade_library_view.dart';
import 'beat_timeline.dart';
import 'director_view.dart';

class CascadeEditor extends StatefulWidget {
  const CascadeEditor({super.key});

  @override
  State<CascadeEditor> createState() => _CascadeEditorState();
}

class _CascadeEditorState extends State<CascadeEditor> {

  Future<bool> _handleBack(CascadeNotifier notifier) async {
    if (!notifier.hasUnsavedChanges) {
      notifier.setActiveCascade(null);
      return true;
    }

    final t = context.t;
    final l = context.l;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(
          l.cascadeUnsavedTitle.toUpperCase(),
          style: TextStyle(
            fontSize: t.fontSize(10),
            letterSpacing: 2,
            color: t.textSecondary,
          ),
        ),
        content: Text(
          l.cascadeUnsavedMessage,
          style: TextStyle(
            color: t.textPrimary,
            fontSize: t.fontSize(11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(
              l.commonCancel.toUpperCase(),
              style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(
              l.commonSave.toUpperCase(),
              style: TextStyle(color: t.accentCascade, fontSize: t.fontSize(9)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(
              l.cascadeDiscard.toUpperCase(),
              style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(9)),
            ),
          ),
        ],
      ),
    );

    if (result == 'save') {
      notifier.saveActiveToLibrary();
      notifier.setActiveCascade(null);
      return true;
    } else if (result == 'discard') {
      notifier.setActiveCascade(null);
      return true;
    }
    return false; // cancel
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CascadeNotifier>(
      builder: (context, notifier, child) {
        final activeCascade = notifier.state.activeCascade;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: activeCascade == null
              ? const CascadeLibraryView()
              : _buildEditorWorkspace(context, notifier),
        );
      },
    );
  }

  Widget _buildEditorWorkspace(BuildContext context, CascadeNotifier notifier) {
    final cascade = notifier.state.activeCascade!;

    return Column(
      children: [
        _buildEditorHeader(context, cascade, notifier),
        const BeatTimeline(),
        const Expanded(
          child: DirectorView(),
        ),
      ],
    );
  }

  Widget _buildEditorHeader(BuildContext context, dynamic cascade, CascadeNotifier notifier) {
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(bottom: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        children: [
          // Back to Library button with label
          TextButton.icon(
            onPressed: () => _handleBack(notifier),
            icon: Icon(Icons.arrow_back, size: mobile ? 16 : 14, color: t.textDisabled),
            label: Text(
              l.cascadeBackToLibrary.toUpperCase(),
              style: TextStyle(
                color: t.textDisabled,
                fontSize: t.fontSize(mobile ? 10 : 8),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: mobile ? 10 : 8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cascade.name.toUpperCase(),
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: t.fontSize(12),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l.cascadeEditorLabel,
                  style: TextStyle(
                    color: t.accentCascade,
                    fontSize: t.fontSize(8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Save button
          ElevatedButton.icon(
            onPressed: () {
              notifier.saveActiveToLibrary();
              showAppSnackBar(context, l.cascadeSavedToLibrary, color: t.accentCascade);
            },
            icon: const Icon(Icons.save, size: 14),
            label: Text(l.commonSave),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.textMinimal,
              foregroundColor: t.textPrimary,
              textStyle: TextStyle(fontSize: t.fontSize(10), fontWeight: FontWeight.bold),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(width: 8),
          // Cast button
          ElevatedButton.icon(
            onPressed: () {
              notifier.saveActiveToLibrary();
              showAppSnackBar(context, l.cascadeSavedToLibrary, color: t.accentCascade);
              Navigator.pop(context);
            },
            icon: Icon(Icons.play_arrow, size: mobile ? 18 : 14),
            label: Text(l.cascadeStartCasting.toUpperCase()),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accentCascade,
              foregroundColor: t.background,
              textStyle: TextStyle(
                fontSize: t.fontSize(mobile ? 11 : 10),
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              padding: EdgeInsets.symmetric(horizontal: mobile ? 18 : 16),
            ),
          ),
        ],
      ),
    );
  }
}
