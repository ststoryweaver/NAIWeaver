import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../providers/cascade_notifier.dart';
import 'cascade_library_view.dart';
import 'beat_timeline.dart';
import 'director_view.dart';

class CascadeEditor extends StatelessWidget {
  const CascadeEditor({super.key});

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        border: Border(bottom: BorderSide(color: t.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 16, color: t.textDisabled),
            onPressed: () {
              notifier.setActiveCascade(null);
            },
          ),
          const SizedBox(width: 8),
          Column(
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
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              notifier.saveActiveToLibrary();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.cascadeSavedToLibrary),
                  backgroundColor: t.accentCascade,
                  duration: const Duration(seconds: 1),
                ),
              );
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
        ],
      ),
    );
  }
}
