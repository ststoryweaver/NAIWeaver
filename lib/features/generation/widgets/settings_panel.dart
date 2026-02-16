import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../../styles.dart';
import '../../gallery/providers/gallery_notifier.dart';
import '../providers/generation_notifier.dart';

class ResolutionOption {
  final String label;
  final int width;
  final int height;

  const ResolutionOption(this.label, this.width, this.height);

  String get value => "${width}x$height";
  String get displayLabel => "$label ${width}x$height";
}

class AdvancedSettingsPanel extends StatelessWidget {
  static List<ResolutionOption> resolutionOptions(BuildContext context) {
    final l = context.l;
    return [
      ResolutionOption(l.resNormalPortrait.toUpperCase(), 832, 1216),
      ResolutionOption(l.resNormalLandscape.toUpperCase(), 1216, 832),
      ResolutionOption(l.resNormalSquare.toUpperCase(), 1024, 1024),
      ResolutionOption(l.resLargePortrait.toUpperCase(), 1024, 1536),
      ResolutionOption(l.resLargeLandscape.toUpperCase(), 1536, 1024),
      ResolutionOption(l.resLargeSquare.toUpperCase(), 1472, 1472),
      ResolutionOption(l.resWallpaperPortrait.toUpperCase(), 1088, 1920),
      ResolutionOption(l.resWallpaperLandscape.toUpperCase(), 1920, 1088),
    ];
  }

  static const List<String> samplers = [
    "k_euler_ancestral",
    "k_euler",
    "k_dpmpp_2s_ancestral",
    "k_dpmpp_2m",
    "k_dpmpp_sde",
  ];

  /// Callback for navigating to the style manager.
  final VoidCallback onManageStyles;

  /// Callback for showing the save-preset dialog.
  final VoidCallback onSavePreset;

  const AdvancedSettingsPanel({
    super.key,
    required this.onManageStyles,
    required this.onSavePreset,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Selector<GenerationNotifier, bool>(
      selector: (_, n) => n.state.isSettingsExpanded,
      builder: (context, isExpanded, _) {
        final notifier = context.read<GenerationNotifier>();

        final mobile = isMobile(context);
        final collapsedH = mobile ? 48.0 : 40.0;
        final expandedH = MediaQuery.of(context).size.height * (mobile ? 0.75 : 0.6);

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: 0,
          right: 0,
          bottom: 0,
          height: isExpanded ? expandedH : collapsedH,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy < -5 && !isExpanded) notifier.toggleSettings();
              if (details.delta.dy > 5 && isExpanded) notifier.toggleSettings();
            },
            child: Container(
              decoration: BoxDecoration(
                color: t.surfaceMid,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: t.borderSubtle),
                boxShadow: [
                  BoxShadow(color: t.background.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: expandedH,
                minHeight: collapsedH,
                child: Column(
                  children: [
                    // Grabber
                    InkWell(
                      onTap: notifier.toggleSettings,
                      child: Container(
                        width: double.infinity,
                        height: collapsedH,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 2,
                              decoration: BoxDecoration(
                                color: t.borderMedium,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            if (!isExpanded)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(context.l.panelAdvancedSettings.toUpperCase(), style: TextStyle(fontSize: t.fontSize(mobile ? 10 : 7), letterSpacing: 2, color: t.hintText, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Scrollable Content — only watch full state when expanded
                    if (isExpanded)
                      Expanded(
                        child: _ExpandedSettingsContent(
                          onManageStyles: onManageStyles,
                          onSavePreset: onSavePreset,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Inner content of the expanded settings panel.
/// Uses context.watch so it rebuilds on state changes,
/// but only exists in the tree when the panel is expanded.
class _ExpandedSettingsContent extends StatefulWidget {
  final VoidCallback onManageStyles;
  final VoidCallback onSavePreset;

  const _ExpandedSettingsContent({
    required this.onManageStyles,
    required this.onSavePreset,
  });

  @override
  State<_ExpandedSettingsContent> createState() => _ExpandedSettingsContentState();
}

class _ExpandedSettingsContentState extends State<_ExpandedSettingsContent> {
  final _negativePromptKey = GlobalKey();
  final _negativePromptFocus = FocusNode();
  bool _stylesExpanded = false;

  @override
  void initState() {
    super.initState();
    _negativePromptFocus.addListener(_onNegativeFocusChanged);
  }

  void _onNegativeFocusChanged() {
    if (_negativePromptFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 400), _scrollToNegativePrompt);
    }
  }

  void _scrollToNegativePrompt() {
    if (!mounted || !_negativePromptFocus.hasFocus) return;
    final ctx = _negativePromptKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  @override
  void dispose() {
    _negativePromptFocus.removeListener(_onNegativeFocusChanged);
    _negativePromptFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<GenerationNotifier>();
    final state = notifier.state;
    final mobile = isMobile(context);
    final t = context.t;
    final sectionOrder = context.watch<ThemeNotifier>().sectionOrder;

    final builders = <String, Widget Function()>{
      'dimensions_seed': () => _buildDimensionsSeed(notifier, state, mobile, t),
      'steps_scale': () => _buildStepsScale(notifier, state, mobile, t),
      'sampler_post': () => _buildSamplerPost(notifier, state, mobile, t),
      'styles': () => _buildStyles(notifier, state, t),
      'negative_prompt': () => _buildNegativePrompt(notifier, t),
      'presets': () => _buildPresets(notifier, state, t),
      'save_to_album': () => _buildSaveToAlbum(context, t, mobile),
    };

    final sections = <Widget>[];
    for (final id in sectionOrder) {
      final builder = builders[id];
      if (builder != null) {
        if (sections.isNotEmpty) sections.add(const SizedBox(height: 24));
        sections.add(builder());
      }
    }
    sections.add(const SizedBox(height: 20));

    return ListView(
      padding: EdgeInsets.fromLTRB(24, 8, 24, mobile ? 40 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom : 40),
      children: sections,
    );
  }

  Widget _buildDimensionsSeed(GenerationNotifier notifier, GenerationState state, bool mobile, VisionTokens t) {
    final labelStyle = TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(mobile ? 12 : 9), letterSpacing: 2, color: t.secondaryText);

    Widget dimensionsField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.panelDimensions.toUpperCase(), style: labelStyle),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: AdvancedSettingsPanel.resolutionOptions(context).any((opt) => opt.width == state.width.toInt() && opt.height == state.height.toInt())
              ? "${state.width.toInt()}x${state.height.toInt()}"
              : null,
          dropdownColor: t.surfaceHigh,
          hint: Text(
            "${state.width.toInt()}x${state.height.toInt()}${!AdvancedSettingsPanel.resolutionOptions(context).any((opt) => opt.width == state.width.toInt() && opt.height == state.height.toInt()) ? ' (${context.l.panelCustom.toUpperCase()})' : ''}",
            style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11)),
          ),
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11), letterSpacing: 1),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fillColor: t.borderSubtle,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              final parts = newValue.split('x');
              notifier.updateSettings(
                width: double.parse(parts[0]),
                height: double.parse(parts[1]),
              );
            }
          },
          items: AdvancedSettingsPanel.resolutionOptions(context).map<DropdownMenuItem<String>>((ResolutionOption opt) {
            return DropdownMenuItem<String>(
              value: opt.value,
              child: Text(opt.displayLabel, style: TextStyle(fontSize: t.fontSize(10))),
            );
          }).toList(),
        ),
      ],
    );

    Widget seedField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.panelSeed.toUpperCase(), style: labelStyle),
        const SizedBox(height: 12),
        TextField(
          controller: notifier.seedController,
          readOnly: state.randomizeSeed,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(fontSize: t.fontSize(11), color: state.randomizeSeed ? t.textDisabled : t.textPrimary),
          decoration: InputDecoration(
            hintText: context.l.panelSeed.toUpperCase(),
            hintStyle: TextStyle(fontSize: t.fontSize(9), color: t.textMinimal),
            fillColor: t.borderSubtle,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: IconButton(
              onPressed: () => notifier.updateSettings(randomizeSeed: !state.randomizeSeed),
              icon: Icon(
                state.randomizeSeed ? Icons.shuffle : Icons.tag,
                size: 14,
                color: state.randomizeSeed ? t.textSecondary : t.textDisabled,
              ),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dimensionsField,
          const SizedBox(height: 16),
          seedField,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: dimensionsField),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: seedField),
      ],
    );
  }

  Widget _buildStepsScale(GenerationNotifier notifier, GenerationState state, bool mobile, VisionTokens t) {
    Widget stepsSlider = _buildCompactSlider(context, context.l.panelSteps.toUpperCase(), state.steps, 1, 50, 1, (v) => notifier.updateSettings(steps: v), t);
    Widget scaleSlider = _buildCompactSlider(context, context.l.panelScale.toUpperCase(), state.scale, 1.0, 30.0, 0.5, (v) => notifier.updateSettings(scale: v), t);

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stepsSlider,
          const SizedBox(height: 16),
          scaleSlider,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: stepsSlider),
        const SizedBox(width: 32),
        Expanded(child: scaleSlider),
      ],
    );
  }

  Widget _buildSamplerPost(GenerationNotifier notifier, GenerationState state, bool mobile, VisionTokens t) {
    final labelStyle = TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(mobile ? 12 : 9), letterSpacing: 2, color: t.secondaryText);

    Widget samplerField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.panelSampler.toUpperCase(), style: labelStyle),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: state.sampler,
          dropdownColor: t.surfaceHigh,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11), letterSpacing: 1),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            fillColor: t.borderSubtle,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          ),
          onChanged: (String? newValue) {
            if (newValue != null) notifier.updateSettings(sampler: newValue);
          },
          items: AdvancedSettingsPanel.samplers.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10))));
          }).toList(),
        ),
      ],
    );

    Widget postProcessingField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.panelPostProcessing.toUpperCase(), style: labelStyle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _buildChipToggle("SMEA", state.smea, (v) => notifier.updateSettings(smea: v), t),
            _buildChipToggle("DYN", state.smeaDyn, (v) => notifier.updateSettings(smeaDyn: v), t),
            _buildChipToggle("CRISP", state.decrisper, (v) => notifier.updateSettings(decrisper: v), t),
          ],
        ),
      ],
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          samplerField,
          const SizedBox(height: 16),
          postProcessingField,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: samplerField),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: postProcessingField),
      ],
    );
  }

  Widget _buildStyleChip(PromptStyle style, bool isSelected, GenerationNotifier notifier, VisionTokens t) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(style.name.toUpperCase(),
              style: TextStyle(fontSize: t.fontSize(8), fontWeight: FontWeight.bold, letterSpacing: 1)),
          if (style.negativeContent.isNotEmpty) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? t.background.withValues(alpha: 0.2) : t.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text("NEG",
                  style: TextStyle(
                      fontSize: t.fontSize(6),
                      fontWeight: FontWeight.w900,
                      color: isSelected ? t.background : t.textTertiary)),
            ),
          ],
          if (style.prefix.isNotEmpty || style.suffix.isNotEmpty) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? t.background.withValues(alpha: 0.2) : t.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text("POS",
                  style: TextStyle(
                      fontSize: t.fontSize(6),
                      fontWeight: FontWeight.w900,
                      color: isSelected ? t.background : t.textTertiary)),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => notifier.toggleStyle(style.name),
      backgroundColor: t.borderSubtle,
      selectedColor: t.accent,
      checkmarkColor: t.background,
      showCheckmark: false,
      labelStyle: TextStyle(color: isSelected ? t.background : t.textTertiary),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      side: BorderSide(color: isSelected ? t.accent : t.textMinimal, width: 0.5),
    );
  }

  Widget _buildStyles(GenerationNotifier notifier, GenerationState state, VisionTokens t) {
    final mobile = isMobile(context);
    final labelStyle = TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(mobile ? 12 : 9), letterSpacing: 2, color: t.secondaryText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l.panelStyles.toUpperCase(), style: labelStyle),
            Row(
              children: [
                if (state.styles.isNotEmpty)
                  IconButton(
                    icon: Icon(_stylesExpanded ? Icons.unfold_less : Icons.unfold_more, size: 14, color: t.textDisabled),
                    onPressed: () => setState(() => _stylesExpanded = !_stylesExpanded),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(right: 12),
                  ),
                IconButton(
                  icon: Icon(Icons.settings_outlined, size: 14, color: t.textDisabled),
                  onPressed: widget.onManageStyles,
                  tooltip: context.l.panelManageStyles.toUpperCase(),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(right: 12),
                ),
                _buildChipToggle(context.l.panelEnabled.toUpperCase(), state.isStyleEnabled, (v) => notifier.updateSettings(isStyleEnabled: v), t),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.styles.isEmpty)
          Text(context.l.panelNoStylesDefined.toUpperCase(), style: TextStyle(fontSize: t.fontSize(8), color: t.textMinimal, letterSpacing: 1))
        else if (_stylesExpanded)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.styles.map((style) {
              final isSelected = state.activeStyleNames.contains(style.name);
              return _buildStyleChip(style, isSelected, notifier, t);
            }).toList(),
          )
        else
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.styles.length,
              itemBuilder: (context, index) {
                final style = state.styles[index];
                final isSelected = state.activeStyleNames.contains(style.name);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildStyleChip(style, isSelected, notifier, t),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNegativePrompt(GenerationNotifier notifier, VisionTokens t) {
    final mobile = isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: _negativePromptKey,
          child: Text(context.l.panelNegativePrompt.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(mobile ? 12 : 9), letterSpacing: 2, color: t.secondaryText)),
        ),
        const SizedBox(height: 12),
        TextField(
          focusNode: _negativePromptFocus,
          controller: notifier.negativePromptController,
          maxLines: 3,
          style: TextStyle(fontSize: t.fontSize(11), color: t.textSecondary, height: 1.4),
          decoration: InputDecoration(
            fillColor: t.borderSubtle.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildPresets(GenerationNotifier notifier, GenerationState state, VisionTokens t) {
    final mobile = isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.l.panelPresets.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(mobile ? 12 : 9), letterSpacing: 2, color: t.secondaryText)),
            IconButton(
              icon: Icon(Icons.add_circle_outline, size: 14, color: t.secondaryText),
              onPressed: widget.onSavePreset,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.presets.isEmpty)
          Text(context.l.panelNoPresetsSaved.toUpperCase(), style: TextStyle(fontSize: t.fontSize(8), color: t.textMinimal, letterSpacing: 1))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.presets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final preset = state.presets[index];
              return Container(
                decoration: BoxDecoration(
                  color: t.borderSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(preset.name.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 1, color: t.textSecondary)),
                  subtitle: Text("${preset.width.toInt()}x${preset.height.toInt()} • ${preset.sampler}", style: TextStyle(fontSize: t.fontSize(8), color: t.textDisabled)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.download, size: 14, color: t.textTertiary),
                        onPressed: () => notifier.applyPreset(preset),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 14, color: t.textMinimal),
                        onPressed: () => _confirmDeletePreset(context, notifier, index, preset.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSaveToAlbum(BuildContext context, VisionTokens t, bool mobile) {
    final gallery = context.watch<GalleryNotifier>();
    final prefs = context.read<PreferencesService>();
    final labelStyle = TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(mobile ? 12 : 9), letterSpacing: 2, color: t.secondaryText);
    final currentId = prefs.defaultSaveAlbumId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.panelSaveToAlbum.toUpperCase(), style: labelStyle),
        const SizedBox(height: 12),
        SizedBox(
          height: mobile ? 42 : 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: gallery.albums.length + 1,
            itemBuilder: (context, index) {
              // Last item is the "+" create-album chip
              if (index == gallery.albums.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(Icons.add, size: mobile ? 14 : 12, color: t.textTertiary),
                    label: Text(
                      context.l.panelNew.toUpperCase(),
                      style: TextStyle(
                        fontSize: t.fontSize(mobile ? 9 : 8),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: t.textTertiary,
                      ),
                    ),
                    backgroundColor: t.borderSubtle,
                    padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 6, vertical: 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    side: BorderSide(color: t.textMinimal, width: 0.5),
                    onPressed: () => _showCreateAlbumDialog(context, gallery, prefs),
                  ),
                );
              }
              final album = gallery.albums[index];
              final isActive = album.id == currentId;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    album.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: t.fontSize(mobile ? 9 : 8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  selected: isActive,
                  onSelected: (_) {
                    prefs.setDefaultSaveAlbumId(isActive ? null : album.id);
                    (context as Element).markNeedsBuild();
                  },
                  backgroundColor: t.borderSubtle,
                  selectedColor: t.accentSuccess,
                  checkmarkColor: t.background,
                  showCheckmark: false,
                  labelStyle: TextStyle(color: isActive ? t.background : t.textTertiary),
                  padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 6, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  side: BorderSide(color: isActive ? t.accentSuccess : t.textMinimal, width: 0.5),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateAlbumDialog(BuildContext context, GalleryNotifier gallery, PreferencesService prefs) {
    final controller = TextEditingController();
    final t = context.read<ThemeNotifier>().tokens;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(ctx.l.panelNewAlbum.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
          decoration: InputDecoration(
            hintText: ctx.l.panelAlbumName.toUpperCase(),
            hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                gallery.createAlbum(controller.text.trim());
                final newAlbum = gallery.albums.last;
                prefs.setDefaultSaveAlbumId(newAlbum.id);
                Navigator.pop(ctx);
              }
            },
            child: Text(ctx.l.commonCreate.toUpperCase(), style: TextStyle(color: t.accent, fontSize: t.fontSize(9))),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePreset(BuildContext context, GenerationNotifier notifier, int index, String name) {
    final t = context.t;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(context.l.panelDeletePreset.toUpperCase(), style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(12), fontWeight: FontWeight.bold)),
        content: Text(context.l.panelDeletePresetConfirm(name), style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(11))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10))),
          ),
          TextButton(
            onPressed: () {
              notifier.deletePreset(index);
              Navigator.pop(context);
            },
            child: Text(context.l.commonDelete.toUpperCase(), style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(10), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSlider(BuildContext context, String label, double value, double min, double max, double step, Function(double) onChanged, VisionTokens t) {
    final mobile = isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: t.fontSize(mobile ? 12 : 9), fontWeight: FontWeight.bold, letterSpacing: 1, color: t.secondaryText)),
            Text(step >= 1 ? value.toInt().toString() : value.toStringAsFixed(1),
              style: TextStyle(fontSize: t.fontSize(mobile ? 13 : 10), fontWeight: FontWeight.bold, color: t.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 1,
            activeTrackColor: t.accent,
            inactiveTrackColor: t.textMinimal,
            thumbColor: t.accent,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: mobile ? 8 : 4),
            overlayShape: RoundSliderOverlayShape(overlayRadius: mobile ? 16 : 0),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / step).toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildChipToggle(String label, bool value, Function(bool) onChanged, VisionTokens t) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: t.fontSize(9), fontWeight: FontWeight.bold, letterSpacing: 1)),
      selected: value,
      onSelected: onChanged,
      backgroundColor: t.borderSubtle,
      selectedColor: t.accent,
      checkmarkColor: t.background,
      labelStyle: TextStyle(color: value ? t.background : t.textTertiary),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      side: BorderSide(color: value ? t.accent : t.textMinimal, width: 0.5),
    );
  }
}

