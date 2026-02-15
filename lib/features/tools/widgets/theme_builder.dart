import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_theme_config.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/color_picker_dialog.dart';

Map<String, String> _sectionDisplayNames(dynamic l) => {
  'dimensions_seed': l.themeSectionDimSeed,
  'steps_scale': l.themeSectionStepsScale,
  'sampler_post': l.themeSectionSamplerPost,
  'styles': l.themeSectionStyles,
  'negative_prompt': l.themeSectionNegPrompt,
  'presets': l.themeSectionPresets,
  'save_to_album': l.themeSectionSaveAlbum,
};

class ThemeBuilder extends StatefulWidget {
  const ThemeBuilder({super.key});

  @override
  State<ThemeBuilder> createState() => _ThemeBuilderState();
}

class _ThemeBuilderState extends State<ThemeBuilder> {
  String? _editingThemeId;
  bool _showingEditor = false;

  static const List<String> _fontOptions = [
    'JetBrains Mono',
    'Fira Code',
    'IBM Plex Mono',
    'Space Mono',
    'Roboto Mono',
    'Inter',
    'Space Grotesk',
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    final themeNotifier = context.watch<ThemeNotifier>();
    final t = themeNotifier.tokens;
    final l = context.l;

    if (mobile) {
      return _showingEditor && _editingThemeId != null
          ? _buildEditor(themeNotifier, t, mobile)
          : _buildList(themeNotifier, t, mobile);
    }

    return Row(
      children: [
        SizedBox(
          width: 260,
          child: _buildList(themeNotifier, t, mobile),
        ),
        VerticalDivider(width: 1, color: t.borderMedium),
        Expanded(
          child: _editingThemeId != null
              ? _buildEditor(themeNotifier, t, mobile)
              : Center(
                  child: Text(
                    l.themeSelectToEdit,
                    style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10), letterSpacing: 2),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildList(ThemeNotifier themeNotifier, VisionTokens t, bool mobile) {
    final l = context.l;
    final allThemes = themeNotifier.allThemes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(l.themeList, style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10), letterSpacing: 2, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: Icon(Icons.add, size: 16, color: t.textSecondary),
                onPressed: () => _createNewTheme(themeNotifier, t),
                tooltip: l.themeNew,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: t.borderSubtle),
        Expanded(
          child: ListView.builder(
            itemCount: allThemes.length,
            itemBuilder: (context, index) {
              final theme = allThemes[index];
              final isActive = themeNotifier.activeThemeId == theme.id;
              return InkWell(
                onTap: () {
                  themeNotifier.setActiveTheme(theme.id);
                  setState(() {
                    _editingThemeId = theme.id;
                    if (mobile) _showingEditor = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? t.accent.withValues(alpha: 0.05) : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: isActive ? t.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme.name,
                              style: TextStyle(
                                color: isActive ? t.textPrimary : t.textSecondary,
                                fontSize: t.fontSize(11),
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildColorStrip(theme),
                          ],
                        ),
                      ),
                      if (!theme.isBuiltIn)
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 14, color: t.textDisabled),
                          onPressed: () => _showDeleteConfirm(context, themeNotifier, theme, t),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorStrip(AppThemeConfig theme) {
    final colors = [theme.background, theme.surfaceHigh, theme.textPrimary, theme.accent, theme.accentEdit];
    return Row(
      children: colors.map((c) {
        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10, width: 0.5),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditor(ThemeNotifier themeNotifier, VisionTokens t, bool mobile) {
    final l = context.l;
    final config = themeNotifier.activeConfig;

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.borderSubtle)),
          ),
          child: Row(
            children: [
              if (mobile)
                IconButton(
                  icon: Icon(Icons.arrow_back, size: 16, color: t.textSecondary),
                  onPressed: () {
                    themeNotifier.clearPreview();
                    setState(() => _showingEditor = false);
                  },
                ),
              Expanded(
                child: Text(
                  config.name,
                  style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11), fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
              if (!config.isBuiltIn) ...[
                TextButton(
                  onPressed: () {
                    if (themeNotifier.isPreviewing) {
                      themeNotifier.commitPreview();
                    }
                  },
                  child: Text(l.themeSave, style: TextStyle(color: t.accent, fontSize: t.fontSize(9), letterSpacing: 1)),
                ),
              ],
              TextButton(
                onPressed: () {
                  themeNotifier.clearPreview();
                  themeNotifier.setActiveTheme(config.id);
                },
                child: Text(l.themeReset, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9), letterSpacing: 1)),
              ),
            ],
          ),
        ),
        // Editor content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview
                _buildSectionHeader(l.themePreview, t),
                const SizedBox(height: 8),
                _buildPreviewCard(config, t),
                const SizedBox(height: 24),

                // Colors
                _buildSectionHeader(l.themeColors, t),
                const SizedBox(height: 8),
                _buildColorRow(l.themeColorBackground, config.background, (c) => _updateConfig(themeNotifier, config.copyWith(background: c)), t),
                _buildColorRow(l.themeColorSurfaceHigh, config.surfaceHigh, (c) => _updateConfig(themeNotifier, config.copyWith(surfaceHigh: c)), t),
                _buildColorRow(l.themeColorSurfaceMid, config.surfaceMid, (c) => _updateConfig(themeNotifier, config.copyWith(surfaceMid: c)), t),
                _buildColorRow(l.themeColorTextPrimary, config.textPrimary, (c) => _updateConfig(themeNotifier, config.copyWith(textPrimary: c)), t),
                _buildColorRow(l.themeColorTextSecondary, config.textSecondary, (c) => _updateConfig(themeNotifier, config.copyWith(textSecondary: c)), t),
                _buildColorRow(l.themeColorTextTertiary, config.textTertiary, (c) => _updateConfig(themeNotifier, config.copyWith(textTertiary: c)), t),
                _buildColorRow(l.themeColorTextDisabled, config.textDisabled, (c) => _updateConfig(themeNotifier, config.copyWith(textDisabled: c)), t),
                _buildColorRow(l.themeColorTextMinimal, config.textMinimal, (c) => _updateConfig(themeNotifier, config.copyWith(textMinimal: c)), t),
                _buildColorRow(l.themeColorBorderStrong, config.borderStrong, (c) => _updateConfig(themeNotifier, config.copyWith(borderStrong: c)), t),
                _buildColorRow(l.themeColorBorderMedium, config.borderMedium, (c) => _updateConfig(themeNotifier, config.copyWith(borderMedium: c)), t),
                _buildColorRow(l.themeColorBorderSubtle, config.borderSubtle, (c) => _updateConfig(themeNotifier, config.copyWith(borderSubtle: c)), t),
                _buildColorRow(l.themeColorAccent, config.accent, (c) => _updateConfig(themeNotifier, config.copyWith(accent: c)), t),
                _buildColorRow(l.themeColorAccentEdit, config.accentEdit, (c) => _updateConfig(themeNotifier, config.copyWith(accentEdit: c)), t),
                _buildColorRow(l.themeColorAccentSuccess, config.accentSuccess, (c) => _updateConfig(themeNotifier, config.copyWith(accentSuccess: c)), t),
                _buildColorRow(l.themeColorAccentDanger, config.accentDanger, (c) => _updateConfig(themeNotifier, config.copyWith(accentDanger: c)), t),
                _buildColorRow(l.themeColorLogo, config.logoColor, (c) => _updateConfig(themeNotifier, config.copyWith(logoColor: c)), t),
                _buildColorRow(l.themeColorCascade, config.accentCascade, (c) => _updateConfig(themeNotifier, config.copyWith(accentCascade: c)), t),
                const SizedBox(height: 24),

                // References
                _buildSectionHeader(l.themeReferences, t),
                const SizedBox(height: 8),
                _buildColorRow(l.themeColorVibeTransfer, config.accentVibeTransfer, (c) => _updateConfig(themeNotifier, config.copyWith(accentVibeTransfer: c)), t),
                _buildColorRow(l.themeColorRefCharacter, config.accentRefCharacter, (c) => _updateConfig(themeNotifier, config.copyWith(accentRefCharacter: c)), t),
                _buildColorRow(l.themeColorRefStyle, config.accentRefStyle, (c) => _updateConfig(themeNotifier, config.copyWith(accentRefStyle: c)), t),
                _buildColorRow(l.themeColorRefCharStyle, config.accentRefCharStyle, (c) => _updateConfig(themeNotifier, config.copyWith(accentRefCharStyle: c)), t),
                const SizedBox(height: 24),

                // Font
                _buildSectionHeader(l.themeFont, t),
                const SizedBox(height: 8),
                _buildFontSelector(themeNotifier, config, t),
                const SizedBox(height: 24),

                // Text scale
                _buildSectionHeader(l.themeTextScale, t),
                const SizedBox(height: 8),
                _buildScaleSlider(themeNotifier, config, t),
                const SizedBox(height: 24),

                // Prompt input
                _buildSectionHeader(l.themePromptInput, t),
                const SizedBox(height: 8),
                _buildPromptFontSizeSlider(themeNotifier, config, t),
                const SizedBox(height: 12),
                _buildPromptMaxLinesSlider(themeNotifier, config, t),
                const SizedBox(height: 24),

                // Bright mode
                _buildSectionHeader(l.themeBrightMode, t),
                const SizedBox(height: 8),
                _buildBrightModeToggle(themeNotifier, config, t),
                const SizedBox(height: 24),

                // Panel layout
                _buildSectionHeader(l.themePanelLayout, t),
                const SizedBox(height: 4),
                Text(
                  l.themePanelLayoutDesc,
                  style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
                ),
                const SizedBox(height: 8),
                _buildSectionOrderList(themeNotifier, t),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VisionTokens t) {
    return Text(
      title,
      style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10), letterSpacing: 2, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPreviewCard(AppThemeConfig config, VisionTokens t) {
    final l = context.l;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Surface card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: config.surfaceHigh,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: config.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.themePreviewHeader, style: TextStyle(color: config.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(l.themePreviewSecondary, style: TextStyle(color: config.textSecondary, fontSize: 10)),
                const SizedBox(height: 4),
                Text(l.themePreviewHint, style: TextStyle(color: config.textTertiary, fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: config.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(l.themePreviewGenerate, style: TextStyle(color: config.background, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: config.accentEdit),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(l.themePreviewEdit, style: TextStyle(color: config.accentEdit, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: config.accentSuccess.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 14, color: config.accentSuccess),
              ),
              const SizedBox(width: 4),
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: config.accentDanger.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 14, color: config.accentDanger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, Color color, Function(Color) onChanged, VisionTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () async {
          final result = await ColorPickerDialog.show(context, initialColor: color, label: label);
          if (result != null) onChanged(result);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: t.borderMedium),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(9), letterSpacing: 1),
              ),
            ),
            Text(
              '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
              style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9), fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSelector(ThemeNotifier themeNotifier, AppThemeConfig config, VisionTokens t) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fontOptions.map((font) {
        final isSelected = config.fontFamily == font;
        return GestureDetector(
          onTap: () => _updateConfig(themeNotifier, config.copyWith(fontFamily: font)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? t.accent.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isSelected ? t.accent : t.borderSubtle),
            ),
            child: Text(
              font,
              style: TextStyle(
                fontFamily: GoogleFonts.getFont(font).fontFamily,
                color: isSelected ? t.accent : t.textSecondary,
                fontSize: t.fontSize(10),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScaleSlider(ThemeNotifier themeNotifier, AppThemeConfig config, VisionTokens t) {
    final l = context.l;
    return Column(
      children: [
        Row(
          children: [
            Text(l.themeSmall, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8))),
            Expanded(
              child: Slider(
                value: config.fontScale,
                min: 0.75,
                max: 1.5,
                divisions: 15,
                activeColor: t.accent,
                inactiveColor: t.borderMedium,
                onChanged: (val) => _updateConfig(themeNotifier, config.copyWith(fontScale: val)),
              ),
            ),
            Text(l.themeLarge, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8))),
          ],
        ),
        Text(
          '${(config.fontScale * 100).round()}%',
          style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10)),
        ),
      ],
    );
  }

  Widget _buildBrightModeToggle(ThemeNotifier themeNotifier, AppThemeConfig config, VisionTokens t) {
    final l = context.l;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.themeBrightText, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                l.themeBrightDesc,
                style: TextStyle(color: t.textTertiary, fontSize: t.fontSize(9)),
              ),
            ],
          ),
        ),
        Switch(
          value: config.brightMode,
          onChanged: (val) => _updateConfig(themeNotifier, config.copyWith(brightMode: val)),
          activeThumbColor: t.accent,
          activeTrackColor: t.textDisabled,
          inactiveThumbColor: t.textMinimal,
          inactiveTrackColor: t.borderSubtle,
        ),
      ],
    );
  }

  Widget _buildPromptFontSizeSlider(ThemeNotifier themeNotifier, AppThemeConfig config, VisionTokens t) {
    final l = context.l;
    return Column(
      children: [
        Row(
          children: [
            Text(l.themeFontSize, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8))),
            Expanded(
              child: Slider(
                value: config.promptFontSize,
                min: 8,
                max: 24,
                divisions: 16,
                activeColor: t.accent,
                inactiveColor: t.borderMedium,
                onChanged: (val) => _updateConfig(themeNotifier, config.copyWith(promptFontSize: val)),
              ),
            ),
            Text('${config.promptFontSize.round()}', style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10))),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptMaxLinesSlider(ThemeNotifier themeNotifier, AppThemeConfig config, VisionTokens t) {
    final l = context.l;
    return Column(
      children: [
        Row(
          children: [
            Text(l.themeHeightLabel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8))),
            Expanded(
              child: Slider(
                value: config.promptMaxLines.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                activeColor: t.accent,
                inactiveColor: t.borderMedium,
                onChanged: (val) => _updateConfig(themeNotifier, config.copyWith(promptMaxLines: val.round())),
              ),
            ),
            Text(l.themeLines(config.promptMaxLines), style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10))),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionOrderList(ThemeNotifier themeNotifier, VisionTokens t) {
    final l = context.l;
    final order = themeNotifier.sectionOrder;
    final displayNames = _sectionDisplayNames(l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: order.length,
          onReorder: themeNotifier.reorderSections,
          proxyDecorator: (child, index, animation) {
            return Material(
              color: t.surfaceHigh,
              borderRadius: BorderRadius.circular(4),
              elevation: 4,
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final id = order[index];
            final name = displayNames[id] ?? id;
            return Container(
              key: ValueKey(id),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: t.borderSubtle.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(Icons.drag_handle, size: 16, color: t.textDisabled),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: t.fontSize(10),
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${index + 1}',
                    style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9)),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: themeNotifier.resetSectionOrder,
            child: Text(
              l.themeReset,
              style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9), letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirm(BuildContext context, ThemeNotifier themeNotifier, AppThemeConfig theme, VisionTokens t) {
    showDialog(
      context: context,
      builder: (context) {
        final l = context.l;
        return AlertDialog(
          backgroundColor: t.surfaceHigh,
          title: Text(l.themeDeleteTitle, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
          content: Text(l.themeDeleteConfirm(theme.name), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(11))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
            ),
            TextButton(
              onPressed: () {
                themeNotifier.deleteUserTheme(theme.id);
                Navigator.pop(context);
              },
              child: Text(l.commonDelete, style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(9))),
            ),
          ],
        );
      },
    );
  }

  void _updateConfig(ThemeNotifier themeNotifier, AppThemeConfig config) {
    if (config.isBuiltIn) {
      // For built-in themes, preview only (no save)
      themeNotifier.previewConfig(config);
    } else {
      // For user themes, preview live and allow save
      themeNotifier.previewConfig(config);
    }
  }

  Future<void> _createNewTheme(ThemeNotifier themeNotifier, VisionTokens t) async {
    final l = context.l;
    final nameController = TextEditingController(text: l.themeCustomTheme);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(l.themeNewTitle, style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(10), letterSpacing: 2)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
          decoration: InputDecoration(
            hintText: l.themeThemeName,
            hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: Text(l.commonCreate, style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(9))),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      try {
        final newTheme = await themeNotifier.saveAsUserTheme(name, themeNotifier.activeConfig);
        if (!mounted) return;
        setState(() {
          _editingThemeId = newTheme.id;
          _showingEditor = true;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.themeCreateFailed(e.toString()))),
        );
      }
    }
  }
}
