import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/models/nai_model.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/tag_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/tag_suggestion_helper.dart';
import '../../../core/widgets/tag_suggestion_overlay.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../../core/widgets/custom_resolution_dialog.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/editable_slider_value.dart';
import '../../../core/widgets/vision_slider.dart';
import '../../../core/services/styles.dart';
import '../../gallery/providers/gallery_notifier.dart';
import '../providers/generation_notifier.dart';
import 'inline_character_editor.dart';

class ResolutionOption {
  final String label;
  final int width;
  final int height;
  final bool isCustom;

  const ResolutionOption(this.label, this.width, this.height, {this.isCustom = false});

  String get value => "${width}x$height";
  String get displayLabel => "$label ${width}x$height";

  Map<String, dynamic> toJson() => {
    'label': label,
    'width': width,
    'height': height,
  };

  factory ResolutionOption.fromJson(Map<String, dynamic> json) => ResolutionOption(
    json['label'] as String,
    json['width'] as int,
    json['height'] as int,
    isCustom: true,
  );
}

class AdvancedSettingsPanel extends StatelessWidget {
  static List<ResolutionOption> resolutionOptions(BuildContext context) {
    final l = context.l;
    final builtIn = [
      ResolutionOption(l.resNormalPortrait.toUpperCase(), 832, 1216),
      ResolutionOption(l.resNormalLandscape.toUpperCase(), 1216, 832),
      ResolutionOption(l.resNormalSquare.toUpperCase(), 1024, 1024),
      ResolutionOption(l.resLargePortrait.toUpperCase(), 1024, 1536),
      ResolutionOption(l.resLargeLandscape.toUpperCase(), 1536, 1024),
      ResolutionOption(l.resLargeSquare.toUpperCase(), 1472, 1472),
      ResolutionOption(l.resWallpaperPortrait.toUpperCase(), 1088, 1920),
      ResolutionOption(l.resWallpaperLandscape.toUpperCase(), 1920, 1088),
    ];
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final custom = _loadCustomResolutions(prefs);
    return [...builtIn, ...custom];
  }

  static List<ResolutionOption> _loadCustomResolutions(PreferencesService prefs) {
    final raw = prefs.customResolutions;
    if (raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ResolutionOption.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomResolution(PreferencesService prefs, ResolutionOption option) async {
    final existing = _loadCustomResolutions(prefs);
    existing.add(option);
    await prefs.setCustomResolutions(jsonEncode(existing.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteCustomResolution(PreferencesService prefs, int index) async {
    final existing = _loadCustomResolutions(prefs);
    if (index >= 0 && index < existing.length) {
      existing.removeAt(index);
      await prefs.setCustomResolutions(jsonEncode(existing.map((e) => e.toJson()).toList()));
    }
  }

  /// Samplers NovelAI offers for the V4/V5 model group (see [NaiModel.samplers]).
  static List<String> get samplers => NaiModel.fallback.samplers;

  /// Callback for navigating to the style manager.
  final VoidCallback onManageStyles;

  /// Callback for opening a specific style's settings.
  final void Function(String styleName)? onEditStyle;

  /// Callback for showing the save-preset dialog.
  final VoidCallback onSavePreset;

  const AdvancedSettingsPanel({
    super.key,
    required this.onManageStyles,
    this.onEditStyle,
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
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        final headerH = mobile ? 48.0 : 40.0;
        final collapsedH = headerH + bottomInset;
        final expandedH = math.max(
          MediaQuery.of(context).size.height * (mobile ? 0.75 : 0.6),
          collapsedH,
        );

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: 0,
          right: 0,
          bottom: 0,
          height: isExpanded ? expandedH : collapsedH,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -300 && !isExpanded) notifier.toggleSettings();
              if (velocity > 300 && isExpanded) notifier.toggleSettings();
            },
            child: Container(
              decoration: BoxDecoration(
                color: t.surfaceHigh,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: t.borderStrong),
                boxShadow: [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
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
                        height: headerH,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 4,
                              decoration: BoxDecoration(
                                color: t.textDisabled,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            if (!isExpanded)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(context.l.panelAdvancedSettings.toUpperCase(), style: TextStyle(fontSize: t.fontSize(mobile ? 10 : 9), letterSpacing: 2, color: t.secondaryText, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Scrollable Content — only watch full state when expanded
                    if (isExpanded)
                      Expanded(
                        child: ExpandedSettingsContent(
                          onManageStyles: onManageStyles,
                          onEditStyle: onEditStyle,
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
class ExpandedSettingsContent extends StatefulWidget {
  final VoidCallback onManageStyles;
  final void Function(String styleName)? onEditStyle;
  final VoidCallback onSavePreset;
  final bool inSidebar;

  const ExpandedSettingsContent({
    super.key,
    required this.onManageStyles,
    this.onEditStyle,
    required this.onSavePreset,
    this.inSidebar = false,
  });

  @override
  State<ExpandedSettingsContent> createState() => _ExpandedSettingsContentState();
}

class _ExpandedSettingsContentState extends State<ExpandedSettingsContent> {
  final _negativePromptKey = GlobalKey();
  final _negativePromptFocus = FocusNode();
  bool _stylesExpanded = false;
  List<DanbooruTag> _negativeSuggestions = [];
  Timer? _negativeTagDebounce;

  @override
  void initState() {
    super.initState();
    _stylesExpanded = Provider.of<PreferencesService>(context, listen: false).uiStylesExpanded;
    _negativePromptFocus.addListener(_onNegativeFocusChanged);
  }

  void _onNegativeFocusChanged() {
    if (_negativePromptFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 400), _scrollToNegativePrompt);
    } else if (_negativeSuggestions.isNotEmpty) {
      setState(() => _negativeSuggestions = []);
    }
  }

  void _onNegativePromptChanged() {
    _negativeTagDebounce?.cancel();
    _negativeTagDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (context.read<GalleryNotifier>().demoMode) return;
      final notifier = context.read<GenerationNotifier>();
      final result = TagSuggestionHelper.getSuggestions(
        text: notifier.negativePromptController.text,
        selection: notifier.negativePromptController.selection,
        tagService: notifier.tagService,
        supportFavorites: true,
        wildcardService: notifier.wildcardService,
      );
      setState(() => _negativeSuggestions = result.suggestions);
    });
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
    _negativeTagDebounce?.cancel();
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

    final compact = widget.inSidebar;
    final hPad = compact ? 16.0 : 24.0;
    final sectionGap = compact ? 16.0 : 24.0;

    final builders = <String, Widget Function()>{
      'model': () => _buildModelSection(notifier, state, mobile, t, compact: compact),
      'dimensions_seed': () => _buildDimensionsSeed(notifier, state, mobile, t, compact: compact),
      'steps_scale': () => _buildStepsScale(notifier, state, mobile, t, compact: compact),
      'sampler_post': () => _buildSamplerPost(notifier, state, mobile, t, compact: compact),
      'characters': () => const InlineCharacterEditor(),
      'styles': () => _buildStyles(notifier, state, t),
      'negative_prompt': () => _buildNegativePrompt(notifier, t),
      'presets': () => _buildPresets(notifier, state, t),
      'save_to_album': () => _buildSaveToAlbum(context, t, mobile),
    };

    final sections = <Widget>[];
    for (final id in sectionOrder) {
      final builder = builders[id];
      if (builder != null) {
        if (sections.isNotEmpty) sections.add(SizedBox(height: sectionGap));
        try {
          sections.add(builder());
        } catch (e) {
          sections.add(Text('Error in $id: $e', style: TextStyle(color: Colors.red, fontSize: t.fontSize(9))));
        }
      }
    }
    sections.add(const SizedBox(height: 20));

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 40 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom),
      children: sections,
    );
  }

  Widget _buildDimensionsSeed(GenerationNotifier notifier, GenerationState state, bool mobile, VisionTokens t, {bool compact = false}) {
    final labelStyle = TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(mobile ? 12 : 9), letterSpacing: 2, color: t.secondaryText);

    Widget dimensionsField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.panelDimensions.toUpperCase(), style: labelStyle),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: AdvancedSettingsPanel.resolutionOptions(context).any((opt) => opt.width == state.width.toInt() && opt.height == state.height.toInt())
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
          onChanged: (String? newValue) async {
            if (newValue == '__custom__') {
              final result = await showCustomResolutionDialog(context);
              if (result != null) {
                notifier.updateSettings(
                  width: result.width.toDouble(),
                  height: result.height.toDouble(),
                );
                if (mounted) setState(() {});
              }
              return;
            }
            if (newValue != null) {
              final parts = newValue.split('x');
              notifier.updateSettings(
                width: double.parse(parts[0]),
                height: double.parse(parts[1]),
              );
            }
          },
          items: [
            ...AdvancedSettingsPanel.resolutionOptions(context).asMap().entries.map<DropdownMenuItem<String>>((entry) {
              final opt = entry.value;
              final builtInCount = 8;
              return DropdownMenuItem<String>(
                value: opt.value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(opt.displayLabel, style: TextStyle(fontSize: t.fontSize(10)), overflow: TextOverflow.ellipsis)),
                    if (opt.isCustom)
                      GestureDetector(
                        onTap: () {
                          final prefs = context.read<PreferencesService>();
                          AdvancedSettingsPanel.deleteCustomResolution(prefs, entry.key - builtInCount);
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.close, size: 14, color: t.textMinimal),
                        ),
                      ),
                  ],
                ),
              );
            }),
            DropdownMenuItem<String>(
              value: '__custom__',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: t.accent),
                  const SizedBox(width: 8),
                  Text(context.l.resCustomEntry.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10), color: t.accent)),
                ],
              ),
            ),
          ],
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

    if (mobile || compact) {
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

  Widget _buildStepsScale(GenerationNotifier notifier, GenerationState state, bool mobile, VisionTokens t, {bool compact = false}) {
    Widget stepsSlider = _buildCompactSlider(context, context.l.panelSteps.toUpperCase(), state.steps, 1, 50, 1, (v) => notifier.updateSettings(steps: v), t, warnAbove: 28);
    Widget scaleSlider = _buildCompactSlider(context, context.l.panelScale.toUpperCase(), state.scale, 1.0, 30.0, 0.5, (v) => notifier.updateSettings(scale: v), t, hardMax: 100.0, warnAbove: 30);

    if (mobile || compact) {
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

  Widget _buildSamplerPost(GenerationNotifier notifier, GenerationState state, bool mobile, VisionTokens t, {bool compact = false}) {
    final labelStyle = TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(mobile ? 12 : 9), letterSpacing: 2, color: t.secondaryText);

    Widget samplerField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.panelSampler.toUpperCase(), style: labelStyle),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: state.sampler,
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
          items: _samplerItems(state).map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10))));
          }).toList(),
        ),
      ],
    );

    final caps = state.model.caps;

    // Noise schedule — only models that expose a picker (V4.5); V5 forces
    // karras, so the control is hidden rather than shown as a no-op (#35).
    Widget? noiseScheduleField;
    if (caps.noiseSchedule) {
      final schedules = state.model.noiseSchedules;
      final value = schedules.contains(state.noiseSchedule)
          ? state.noiseSchedule
          : state.model.defaults.noiseSchedule;
      noiseScheduleField = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOISE SCHEDULE', style: labelStyle),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: value,
            dropdownColor: t.surfaceHigh,
            style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11), letterSpacing: 1),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              fillColor: t.borderSubtle,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            ),
            onChanged: (String? newValue) {
              if (newValue != null) notifier.updateSettings(noiseSchedule: newValue);
            },
            items: schedules.map<DropdownMenuItem<String>>((String v) {
              return DropdownMenuItem<String>(value: v, child: Text(v.toUpperCase(), style: TextStyle(fontSize: t.fontSize(10))));
            }).toList(),
          ),
        ],
      );
    }

    // Prompt Guidance Rescale (`cfg_rescale`), 0 = off.
    Widget? rescaleSlider;
    if (caps.cfgRescale) {
      rescaleSlider = _buildCompactSlider(
        context,
        'GUIDANCE RESCALE',
        state.cfgRescale,
        0.0,
        1.0,
        0.02,
        (v) => notifier.updateSettings(cfgRescale: v),
        t,
      );
    }

    // Variety+ — a toggle, since NovelAI exposes it as one. On = the sigma
    // floor their UI sends; off = null (key present but unset).
    Widget? varietyToggle;
    if (caps.varietyPlus) {
      final on = state.varietyBoostSigma != null;
      varietyToggle = InkWell(
        onTap: () => notifier.updateSettings(
          varietyBoostSigma: on ? null : _varietyDefaultSigma,
          clearVarietyBoost: on,
        ),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: on ? t.accent : t.borderMedium),
            color: on ? t.accent.withValues(alpha: 0.15) : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: mobile ? 16 : 14, color: on ? t.accent : t.textDisabled),
              const SizedBox(width: 8),
              Text(
                'VARIETY+',
                style: TextStyle(
                  color: on ? t.accent : t.textDisabled,
                  fontSize: t.fontSize(mobile ? 10 : 9),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget furryToggle = InkWell(
      onTap: () => notifier.updateSettings(furryMode: !state.furryMode),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: state.furryMode ? const Color(0xFFFF9800) : t.borderMedium,
          ),
          color: state.furryMode
              ? const Color(0xFFFF9800).withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets,
              size: mobile ? 16 : 14,
              color: state.furryMode ? const Color(0xFFFF9800) : t.textDisabled,
            ),
            const SizedBox(width: 8),
            Text(
              'FURRY',
              style: TextStyle(
                color: state.furryMode ? const Color(0xFFFF9800) : t.textDisabled,
                fontSize: t.fontSize(mobile ? 10 : 9),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );

    if (mobile || compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          samplerField,
          if (noiseScheduleField != null) ...[
            const SizedBox(height: 16),
            noiseScheduleField,
          ],
          if (rescaleSlider != null) ...[
            const SizedBox(height: 16),
            rescaleSlider,
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (varietyToggle != null) ...[
                varietyToggle,
                const SizedBox(width: 12),
              ],
              furryToggle,
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: samplerField),
            if (noiseScheduleField != null) ...[
              const SizedBox(width: 24),
              Expanded(flex: 1, child: noiseScheduleField),
            ],
            const SizedBox(width: 24),
            if (varietyToggle != null) ...[
              varietyToggle,
              const SizedBox(width: 12),
            ],
            furryToggle,
          ],
        ),
        if (rescaleSlider != null) ...[
          const SizedBox(height: 16),
          rescaleSlider,
        ],
      ],
    );
  }

  /// Sigma floor NovelAI's frontend sends when Variety+ is switched on.
  static const double _varietyDefaultSigma = 58.0;

  /// Sampler list for the active model; keeps a now-unlisted sampler (e.g.
  /// restored from an old session) visible so the dropdown never asserts.
  List<String> _samplerItems(GenerationState state) {
    final items = List<String>.from(state.model.samplers);
    if (!items.contains(state.sampler)) items.add(state.sampler);
    return items;
  }

  Widget _buildModelSection(GenerationNotifier notifier, GenerationState state, bool mobile, VisionTokens t, {bool compact = false}) {
    final labelStyle = TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(mobile ? 12 : 9), letterSpacing: 2, color: t.secondaryText);
    final model = state.model;
    final caps = model.caps;
    final usage = state.subscription?.usage;
    final costKind = notifier.costKind;

    // Pre-flight cost label (free / V5 allowance / costs Anlas).
    String? costLabel;
    Color costColor = t.textDisabled;
    switch (costKind) {
      case NaiCostKind.free:
        costLabel = 'FREE ON OPUS';
        costColor = const Color(0xFF4CAF50);
      case NaiCostKind.allowance:
        costLabel = usage != null
            ? 'V5 ALLOWANCE · ${usage.remainingPercent.toStringAsFixed(0)}% (~${usage.imagesLeft} LEFT)'
            : 'USES V5 ALLOWANCE';
        costColor = usage != null && usage.isLow ? const Color(0xFFFF9800) : t.accent;
      case NaiCostKind.anlas:
        costLabel = 'COSTS ANLAS';
        costColor = const Color(0xFFFF9800);
      case NaiCostKind.unknown:
        costLabel = null;
    }

    Widget modelChip(NaiModel m) {
      final selected = m == model;
      final color = m.isV5 ? t.accent : const Color(0xFF4CAF50);
      return Tooltip(
        message: m.capsHint,
        child: InkWell(
          onTap: () => notifier.updateSettings(model: m),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 10, vertical: mobile ? 8 : 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: selected ? color : t.borderMedium),
              color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            ),
            child: Text(
              m.label.toUpperCase(),
              style: TextStyle(
                color: selected ? color : t.textDisabled,
                fontSize: t.fontSize(mobile ? 10 : 9),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    Widget toggle({
      required String label,
      required IconData icon,
      required bool value,
      required Color color,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: value ? color : t.borderMedium),
              color: value ? color.withValues(alpha: 0.15) : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: mobile ? 16 : 14, color: value ? color : t.textDisabled),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: value ? color : t.textDisabled,
                    fontSize: t.fontSize(mobile ? 10 : 9),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final defaultsTip = "Reset steps / scale / sampler to NovelAI's defaults for "
        "${model.label} (${model.defaults.steps} steps, scale ${model.defaults.scale.toStringAsFixed(1)})";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('MODEL', style: labelStyle),
            const Spacer(),
            Tooltip(
              message: defaultsTip,
              child: InkWell(
                onTap: notifier.applyModelDefaults,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restart_alt, size: mobile ? 14 : 12, color: t.textDisabled),
                      const SizedBox(width: 4),
                      Text('DEFAULTS', style: TextStyle(fontSize: t.fontSize(mobile ? 9 : 8), letterSpacing: 1.5, fontWeight: FontWeight.bold, color: t.textDisabled)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NaiModel.values.map(modelChip).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          model.capsHint,
          style: TextStyle(
            fontSize: t.fontSize(mobile ? 9 : 8),
            color: t.textMinimal,
            letterSpacing: 0.5,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (caps.transparency || costLabel != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (caps.transparency)
                toggle(
                  label: 'TRANSPARENT BG',
                  icon: Icons.blur_on,
                  value: state.transparentBackground,
                  color: t.accent,
                  tooltip: 'Native RGBA output: adds "transparent background" to the prompt and requests straight alpha (V5 only)',
                  onTap: () => notifier.updateSettings(transparentBackground: !state.transparentBackground),
                ),
              if (costLabel != null)
                Tooltip(
                  message: usage != null
                      ? 'Opus V5 allowance: ${usage.remainingPercent.toStringAsFixed(1)}% left (~${usage.imagesLeft} images), '
                          'refills ~${usage.percentPerDay.toStringAsFixed(1)}%/day (~${usage.imagesPerDay} images). '
                          'When empty, V5 renders cost Anlas; V4.5 stays free.'
                      : 'Free on Opus: one image, no base image, up to 1024x1024, up to 28 steps. '
                          'V5 draws from the Opus usage limit; V4.5 is unlimited.',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: costColor.withValues(alpha: 0.6)),
                      color: costColor.withValues(alpha: 0.08),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          costKind == NaiCostKind.allowance
                              ? Icons.battery_charging_full
                              : (costKind == NaiCostKind.anlas ? Icons.toll : Icons.check_circle_outline),
                          size: mobile ? 14 : 12,
                          color: costColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          costLabel,
                          style: TextStyle(
                            color: costColor,
                            fontSize: t.fontSize(mobile ? 9 : 8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStyleChip(PromptStyle style, bool isSelected, GenerationNotifier notifier, VisionTokens t) {
    final tooltipBuffer = StringBuffer(style.name);
    if (style.prefix.isNotEmpty) {
      tooltipBuffer.write('\n+ ${style.prefix}');
    }
    if (style.suffix.isNotEmpty) {
      tooltipBuffer.write('\n+ ${style.suffix}');
    }
    if (style.negativeContent.isNotEmpty) {
      tooltipBuffer.write('\nNEG: ${style.negativeContent}');
    }
    return Tooltip(
      message: tooltipBuffer.toString(),
      waitDuration: const Duration(milliseconds: 200),
      preferBelow: false,
      textStyle: TextStyle(color: t.textPrimary, fontSize: t.fontSize(9)),
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: t.borderMedium),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: GestureDetector(
        onLongPress: widget.onEditStyle != null ? () => widget.onEditStyle!(style.name) : null,
        child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(style.name.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: t.fontSize(8), fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
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
        onSelected: (_) {
          if (HardwareKeyboard.instance.isControlPressed && widget.onEditStyle != null) {
            widget.onEditStyle!(style.name);
          } else {
            notifier.toggleStyle(style.name);
          }
        },
        backgroundColor: t.borderSubtle,
        selectedColor: t.accent,
        checkmarkColor: t.background,
        showCheckmark: false,
        labelStyle: TextStyle(color: isSelected ? t.background : t.textTertiary),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        side: BorderSide(color: isSelected ? t.accent : t.textMinimal, width: 0.5),
      ),
      ),
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
                    tooltip: context.l.settingsStylesToggle,
                    onPressed: () {
                      setState(() => _stylesExpanded = !_stylesExpanded);
                      context.read<PreferencesService>().setUiStylesExpanded(_stylesExpanded);
                    },
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
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
            },
          ),
          child: TextField(
            focusNode: _negativePromptFocus,
            controller: notifier.negativePromptController,
            maxLines: 3,
            onTap: _scrollToNegativePrompt,
            onChanged: (_) => _onNegativePromptChanged(),
            style: TextStyle(fontSize: t.fontSize(11), color: t.textSecondary, height: 1.4),
            decoration: InputDecoration(
              fillColor: t.borderSubtle,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (_negativeSuggestions.isNotEmpty)
          TagSuggestionOverlay(
            suggestions: _negativeSuggestions,
            onTagSelected: (tag) {
              TagSuggestionHelper.applyTag(notifier.negativePromptController, tag);
              setState(() => _negativeSuggestions = []);
            },
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
              tooltip: context.l.mainSavePreset,
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
                        tooltip: context.l.presetLoad,
                        onPressed: () => notifier.applyPreset(preset),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 14, color: t.textMinimal),
                        tooltip: context.l.commonDelete,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l.panelSaveToAlbum.toUpperCase(), style: labelStyle),
        const SizedBox(height: 12),
        StatefulBuilder(
          builder: (context, setChipState) {
            final currentId = prefs.defaultSaveAlbumId;
            return SizedBox(
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
                        setChipState(() {});
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
            );
          },
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

  Future<void> _confirmDeletePreset(BuildContext context, GenerationNotifier notifier, int index, String name) async {
    final t = context.t;
    final confirm = await showConfirmDialog(
      context,
      title: context.l.panelDeletePreset,
      message: context.l.panelDeletePresetConfirm(name),
      confirmLabel: context.l.commonDelete,
      confirmColor: t.accentDanger,
    );
    if (confirm == true) {
      notifier.deletePreset(index);
    }
  }

  Widget _buildCompactSlider(BuildContext context, String label, double value, double min, double max, double step, Function(double) onChanged, VisionTokens t, {double? warnAbove, double? hardMin, double? hardMax}) {
    final mobile = isMobile(context);
    final isWarning = warnAbove != null && value > warnAbove;
    final isInteger = step >= 1;
    // The slider itself stays on [min, max]; if the typed value exceeds the
    // soft max, pin the thumb to the end so the track stays valid.
    final sliderValue = value.clamp(min, max).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: t.fontSize(mobile ? 12 : 9), fontWeight: FontWeight.bold, letterSpacing: 1, color: t.secondaryText)),
            EditableSliderValue(
              value: value,
              softMin: min,
              softMax: max,
              hardMin: hardMin,
              hardMax: hardMax,
              isInteger: isInteger,
              decimals: 1,
              onChanged: onChanged,
              style: TextStyle(fontSize: t.fontSize(mobile ? 13 : 10), fontWeight: FontWeight.bold, color: isWarning ? t.accentDanger : t.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        VisionSlider(
          value: sliderValue,
          min: min,
          max: max,
          divisions: ((max - min) / step).toInt(),
          activeColor: isWarning ? t.accentDanger : t.accent,
          inactiveColor: t.textMinimal,
          thumbColor: isWarning ? t.accentDanger : t.accent,
          thumbRadius: mobile ? 8 : 4,
          overlayRadius: mobile ? 16 : 0,
          trackHeight: 1,
          onChanged: (v) => onChanged(isInteger ? v.roundToDouble() : double.parse(v.toStringAsFixed(1))),
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

