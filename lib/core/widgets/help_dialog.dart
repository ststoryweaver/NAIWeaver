import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/theme_extensions.dart';
import '../../features/gallery/ui/gallery_screen.dart';
import '../../features/tools/tools_hub_screen.dart';

void showHelpDialog(BuildContext context) {
  final t = context.tRead;
  final l = context.l;
  showDialog(
    context: context,
    builder: (context) {
      final shortcuts = _getShortcuts(l);
      final features = _getFeatures(l);
      return AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(
          l.helpTitle.toUpperCase(),
          style: TextStyle(
            color: t.textPrimary,
            fontSize: t.fontSize(16),
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9 > 520
              ? 520
              : MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SHORTCUTS ---
                _sectionHeader(t, l.helpShortcuts.toUpperCase()),
                const SizedBox(height: 8),
                ...shortcuts.map((s) => _shortcutRow(t, s.syntax, s.description)),
                const SizedBox(height: 16),
                Divider(color: t.textDisabled.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: 16),
                // --- FEATURES ---
                _sectionHeader(t, l.helpFeatures.toUpperCase()),
                const SizedBox(height: 8),
                ...features.map((f) => _featureRow(context, t, f)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.commonClose.toUpperCase(),
              style: TextStyle(
                color: t.accent,
                fontSize: t.fontSize(12),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget _sectionHeader(dynamic t, String label) {
  return Text(
    label,
    style: TextStyle(
      color: t.textSecondary,
      fontSize: t.fontSize(11),
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    ),
  );
}

Widget _shortcutRow(dynamic t, String syntax, String description) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            syntax,
            style: TextStyle(
              color: t.accent,
              fontSize: t.fontSize(12),
              fontFamily: 'Consolas',
              fontFamilyFallback: const ['monospace'],
            ),
          ),
        ),
        Expanded(
          child: Text(
            description,
            style: TextStyle(
              color: t.textTertiary,
              fontSize: t.fontSize(12),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _featureRow(BuildContext context, dynamic t, _Feature feature) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: feature.name,
                  style: TextStyle(
                    color: t.textSecondary,
                    fontSize: t.fontSize(12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: '  ${feature.description}',
                  style: TextStyle(
                    color: t.textTertiary,
                    fontSize: t.fontSize(12),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 26,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Navigator.pop(context); // close dialog
              feature.navigate(context);
            },
            child: Text(
              '\u2192',
              style: TextStyle(
                color: t.accent,
                fontSize: t.fontSize(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// --- Data ---

class _Shortcut {
  final String syntax;
  final String description;
  const _Shortcut(this.syntax, this.description);
}

List<_Shortcut> _getShortcuts(dynamic l) => [
  _Shortcut('__name__', l.helpShortcutWildcard),
  _Shortcut('__', l.helpShortcutWildcardBrowse),
  _Shortcut('/f', l.helpShortcutFavorites),
  _Shortcut('/fa /fc /fg /fr /fm', l.helpShortcutFavCategories),
  _Shortcut('artist:', l.helpShortcutArtistPrefix),
  _Shortcut('Hold tap', l.helpShortcutHoldDismiss),
  _Shortcut('Enter', l.helpShortcutEnter),
  _Shortcut('Drag & drop PNG', l.helpShortcutDragDrop),
];

class _Feature {
  final String name;
  final String description;
  final void Function(BuildContext context) navigate;
  const _Feature(this.name, this.description, this.navigate);
}

List<_Feature> _getFeatures(dynamic l) => [
  _Feature(l.helpFeatureGallery, l.helpFeatureGalleryDesc, (ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const GalleryScreen()));
  }),
  _Feature(l.helpFeatureWildcards, l.helpFeatureWildcardsDesc, (ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'wildcards')));
  }),
  _Feature(l.helpFeatureStyles, l.helpFeatureStylesDesc, (ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'styles')));
  }),
  _Feature(l.helpFeaturePresets, l.helpFeaturePresetsDesc, (ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'presets')));
  }),
  _Feature(l.helpFeatureDirectorRef, l.helpFeatureDirectorRefDesc, (ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'director_ref')));
  }),
  _Feature(l.helpFeatureVibeTransfer, l.helpFeatureVibeTransferDesc, (ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'director_ref')));
  }),
  _Feature(l.helpFeatureCascade, l.helpFeatureCascadeDesc, (ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'cascade')));
  }),
  _Feature(l.helpFeatureImg2img, l.helpFeatureImg2imgDesc, (ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'img2img')));
  }),
  _Feature(l.helpFeatureThemes, l.helpFeatureThemesDesc, (ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'theme')));
  }),
  _Feature(l.helpFeaturePacks, l.helpFeaturePacksDesc, (ctx) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ToolsHubScreen(initialToolId: 'packs')));
  }),
];
