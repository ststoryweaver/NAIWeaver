import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/tag_suggestion_helper.dart';
import '../../../../core/widgets/tag_suggestion_overlay.dart';
import '../providers/cascade_notifier.dart';
import '../models/cascade_beat.dart';
import '../../../characters/providers/character_library_notifier.dart';
import '../../../generation/widgets/nai_grid_selector.dart';
import '../../../generation/widgets/action_interaction_sheet.dart';
import '../../../generation/models/nai_character.dart';
import '../../../generation/providers/generation_notifier.dart';
import '../../../generation/widgets/settings_panel.dart';
import '../../../../core/widgets/custom_resolution_dialog.dart';
import '../../../../core/services/tag_service.dart';

class DirectorView extends StatefulWidget {
  const DirectorView({super.key});

  @override
  State<DirectorView> createState() => _DirectorViewState();
}

class _DirectorViewState extends State<DirectorView> {
  final TextEditingController _sceneController = TextEditingController();
  final FocusNode _sceneFocusNode = FocusNode();
  final TextEditingController _envController = TextEditingController();
  final FocusNode _envFocusNode = FocusNode();
  final Map<int, TextEditingController> _posControllers = {};
  final Map<int, TextEditingController> _negControllers = {};
  final Map<int, FocusNode> _posFocusNodes = {};
  final Map<int, FocusNode> _negFocusNodes = {};
  int? _lastBeatIndex;

  // Tag suggestion state
  List<DanbooruTag> _suggestions = [];
  Timer? _debounce;
  TextEditingController? _activeSuggestionController;
  ValueChanged<String>? _activeSuggestionOnChanged;

  @override
  void initState() {
    super.initState();
    _sceneFocusNode.addListener(_onFocusChanged);
    _envFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sceneController.dispose();
    _sceneFocusNode.removeListener(_onFocusChanged);
    _sceneFocusNode.dispose();
    _envController.dispose();
    _envFocusNode.removeListener(_onFocusChanged);
    _envFocusNode.dispose();
    for (var c in _posControllers.values) {
      c.dispose();
    }
    for (var c in _negControllers.values) {
      c.dispose();
    }
    for (var f in _posFocusNodes.values) {
      f.removeListener(_onFocusChanged);
      f.dispose();
    }
    for (var f in _negFocusNodes.values) {
      f.removeListener(_onFocusChanged);
      f.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    // Clear suggestions when all prompt fields lose focus
    Future.microtask(() {
      if (!mounted) return;
      final anyFocused = _sceneFocusNode.hasFocus ||
          _envFocusNode.hasFocus ||
          _posFocusNodes.values.any((f) => f.hasFocus) ||
          _negFocusNodes.values.any((f) => f.hasFocus);
      if (!anyFocused && _suggestions.isNotEmpty) {
        setState(() => _suggestions = []);
      }
    });
  }

  void _handleTagInput(TextEditingController controller, ValueChanged<String> onChanged, String value, TagService? tagService) {
    onChanged(value);
    _activeSuggestionController = controller;
    _activeSuggestionOnChanged = onChanged;
    _debounce?.cancel();
    if (tagService == null) {
      setState(() => _suggestions = []);
      return;
    }
    final wildcardService = context.read<GenerationNotifier>().wildcardService;
    final charLib = context.read<CharacterLibraryNotifier>();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final result = TagSuggestionHelper.getSuggestions(
        text: controller.text,
        selection: controller.selection,
        tagService: tagService,
        wildcardService: wildcardService,
        characterSuggestionsFor: (q) => charLib.suggestionTags(q),
      );
      setState(() => _suggestions = result.suggestions);
    });
  }

  void _onTagSelected(DanbooruTag tag) {
    if (_activeSuggestionController == null) return;
    TagSuggestionHelper.applyTag(_activeSuggestionController!, tag);
    _activeSuggestionOnChanged?.call(_activeSuggestionController!.text);
    setState(() => _suggestions = []);
  }

  void _syncControllers(CascadeBeat beat, int beatIndex, int charCount) {
    if (_lastBeatIndex != beatIndex) {
      _sceneController.text = beat.sceneTags;
      _envController.text = beat.environmentTags;
      for (int i = 0; i < charCount; i++) {
        final pos = _posControllers.putIfAbsent(i, () => TextEditingController());
        final neg = _negControllers.putIfAbsent(i, () => TextEditingController());
        if (!_posFocusNodes.containsKey(i)) {
          final fn = FocusNode();
          fn.addListener(_onFocusChanged);
          _posFocusNodes[i] = fn;
        }
        if (!_negFocusNodes.containsKey(i)) {
          final fn = FocusNode();
          fn.addListener(_onFocusChanged);
          _negFocusNodes[i] = fn;
        }
        pos.text = beat.characterSlots[i].positivePrompt;
        neg.text = beat.characterSlots[i].negativePrompt;
      }
      _lastBeatIndex = beatIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;

    return Consumer<CascadeNotifier>(
      builder: (context, notifier, child) {
        final state = notifier.state;
        if (state.activeCascade == null || state.selectedBeatIndex == null) {
          return Center(child: Text(l.cascadeNoBeatSelected, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10), letterSpacing: 2)));
        }

        final beatIndex = state.selectedBeatIndex!;
        final beat = state.activeCascade!.beats[beatIndex];
        final charCount = state.activeCascade!.characterCount;
        final useCoords = state.activeCascade!.useCoords;

        _syncControllers(beat, beatIndex, charCount);

        final tagService = context.read<GenerationNotifier>().tagService;
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile(context) ? 16.0 : 24.0).copyWith(
            bottom: (isMobile(context) ? 16.0 : 24.0) + keyboardHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Base-prompt fields read top-to-bottom in prompt order:
              // SCENE / ACTION (what's happening) → ENVIRONMENT (where).
              _buildBaseTagField(
                header: l.cascadeScenePrompt,
                subLabel: l.cascadeSceneSubLabel,
                hint: l.cascadeSceneHint,
                controller: _sceneController,
                focusNode: _sceneFocusNode,
                onChanged: (v) => notifier.updateActiveBeat(beat.copyWith(sceneTags: v)),
                tagService: tagService,
                // Apply this beat's scene/action to every beat — the core
                // "fixed shot, changing action" workflow this feature enables.
                trailing: state.activeCascade!.beats.length > 1
                    ? _buildApplySceneButton(notifier, beat)
                    : null,
              ),
              const SizedBox(height: 24),
              _buildBaseTagField(
                header: l.cascadeEnvironmentPrompt,
                subLabel: l.cascadeEnvSubLabel,
                hint: l.cascadeEnvHint,
                controller: _envController,
                focusNode: _envFocusNode,
                onChanged: (v) => notifier.updateActiveBeat(beat.copyWith(environmentTags: v)),
                tagService: tagService,
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(l.cascadeCharacterSlots),
              const SizedBox(height: 16),
              Column(
                children: [
                  for (int i = 0; i < charCount; i++)
                    _buildSlotItem(context, i, beat, notifier, useCoords),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(l.cascadeBeatSettings),
              const SizedBox(height: 16),
              _buildBeatSettings(beat, notifier),
              const SizedBox(height: 16),
              _buildSectionHeader(l.cascadeStyles),
              const SizedBox(height: 8),
              _buildStyleSelector(beat, notifier),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    final t = context.t;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: t.accentCascade,
            fontSize: t.fontSize(10),
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: t.accentCascade.withValues(alpha: 0.1))),
      ],
    );
  }

  /// A labelled base-prompt tag field with Danbooru autocomplete. Shared by the
  /// SCENE / ACTION and ENVIRONMENT sections, which are visually identical and
  /// both feed the NovelAI base prompt. [subLabel] is a muted one-liner under the
  /// header that stays visible after the field has content (the hint disappears),
  /// disambiguating the two otherwise-identical cyan headers. [trailing] is an
  /// optional action shown on the header row.
  Widget _buildBaseTagField({
    required String header,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    String? subLabel,
    Widget? trailing,
    TagService? tagService,
  }) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionHeader(header)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
        if (subLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subLabel,
              style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), letterSpacing: 0.5),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (val) => _handleTagInput(controller, onChanged, val, tagService),
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13), height: 1.4),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(11)),
            filled: true,
            fillColor: t.accentCascade.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: t.accentCascade.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: t.accentCascade.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: t.accentCascade.withValues(alpha: 0.2)),
            ),
          ),
        ),
        if (_activeSuggestionController == controller && _suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TagSuggestionOverlay(
              suggestions: _suggestions,
              onTagSelected: _onTagSelected,
            ),
          ),
      ],
    );
  }

  /// "Apply to all" action for the SCENE field: copies this beat's scene/action
  /// tags onto every beat in the cascade (fixed shot, changing action).
  Widget _buildApplySceneButton(CascadeNotifier notifier, CascadeBeat beat) {
    final t = context.t;
    final l = context.l;
    return TextButton.icon(
      onPressed: () {
        notifier.applySceneToAllBeats(beat.sceneTags);
        showAppSnackBar(context, l.cascadeSceneApplied, color: t.accentCascade);
      },
      icon: Icon(Icons.copy_all, size: 14, color: t.accentCascade),
      label: Text(
        l.cascadeApplyToAll.toUpperCase(),
        style: TextStyle(
          color: t.accentCascade,
          fontSize: t.fontSize(8),
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildSlotItem(BuildContext context, int index, CascadeBeat beat, CascadeNotifier notifier, bool useCoords) {
    final t = context.t;
    final l = context.l;
    final slot = beat.characterSlots[index];
    final generationNotifier = context.read<GenerationNotifier>();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.accentCascade.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.accentCascade.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.accentCascade,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: t.background, fontWeight: FontWeight.bold, fontSize: t.fontSize(12)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l.cascadeCharacterSlotN(index + 1),
                style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11), fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const Spacer(),
              _buildActionLinker(context, index, beat, notifier),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (useCoords)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.cascadePosition, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: NaiGridSelector(
                          freeform: context.select<GenerationNotifier?, bool>(
                              (n) => n?.state.model.caps.freeformPosition ?? false),
                          selectedCoordinate: slot.position,
                          onCoordinateSelected: (coord) {
                            final updatedSlots = List<BeatCharacterSlot>.from(beat.characterSlots);
                            updatedSlots[index] = slot.copyWith(position: coord);
                            notifier.updateActiveBeat(beat.copyWith(characterSlots: updatedSlots));
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      l.cascadeAiPosition,
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: t.fontSize(10),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPromptField(
                      label: l.cascadePositivePrompt,
                      hint: l.cascadeCharHint,
                      controller: _posControllers[index]!,
                      focusNode: _posFocusNodes[index]!,
                      onChanged: (val) {
                        final updatedSlots = List<BeatCharacterSlot>.from(beat.characterSlots);
                        updatedSlots[index] = slot.copyWith(positivePrompt: val);
                        notifier.updateActiveBeat(beat.copyWith(characterSlots: updatedSlots));
                      },
                      tagService: generationNotifier.tagService,
                    ),
                    const SizedBox(height: 16),
                    _buildPromptField(
                      label: l.cascadeNegativePrompt,
                      hint: l.cascadeAvoidHint,
                      controller: _negControllers[index]!,
                      focusNode: _negFocusNodes[index]!,
                      onChanged: (val) {
                        final updatedSlots = List<BeatCharacterSlot>.from(beat.characterSlots);
                        updatedSlots[index] = slot.copyWith(negativePrompt: val);
                        notifier.updateActiveBeat(beat.copyWith(characterSlots: updatedSlots));
                      },
                      tagService: generationNotifier.tagService,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (slot.actionTags.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(top: 16.0),
               child: Wrap(
                 spacing: 8,
                 runSpacing: 8,
                 children: [
                   for (final tag in slot.actionTags)
                     _buildActionChip(context, beat, notifier, index, slot, tag),
                 ],
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildPromptField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    TagService? tagService,
  }) {
    final t = context.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (val) => _handleTagInput(controller, onChanged, val, tagService),
          maxLines: 2,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11), height: 1.4),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
            filled: true,
            fillColor: t.background.withValues(alpha: 0.2),
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.borderSubtle)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.borderSubtle)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.accentCascade.withValues(alpha: 0.2))),
          ),
        ),
        if (_activeSuggestionController == controller && _suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TagSuggestionOverlay(
              suggestions: _suggestions,
              onTagSelected: _onTagSelected,
            ),
          ),
      ],
    );
  }

  Widget _buildActionLinker(BuildContext context, int index, CascadeBeat beat, CascadeNotifier notifier) {
    final t = context.t;
    final l = context.l;
    return IconButton(
      icon: Icon(Icons.link, size: 18, color: t.accentCascade),
      onPressed: () {
        _showLinkerMenu(context, index, beat, notifier);
      },
      tooltip: l.cascadeLinkAction,
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
    );
  }

  void _showLinkerMenu(BuildContext context, int sourceIndex, CascadeBeat beat, CascadeNotifier notifier) {
    final t = context.t;
    final targetIndex = (sourceIndex + 1) % beat.characterSlots.length;
    // Build dummy character list for the sheet's label display
    final sheetChars = beat.characterSlots.asMap().entries.map((e) =>
      NaiCharacter(prompt: '', uc: '', center: NaiCoordinate(x: 0.5, y: 0.5), name: 'C${e.key + 1}'),
    ).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surfaceMid,
      builder: (context) => ActionInteractionSheet(
        sourceIndices: [sourceIndex],
        targetIndices: [targetIndex],
        initialType: InteractionType.sourceTarget,
        characters: sheetChars,
        onSave: (interaction) {
          final updatedSlots = List<BeatCharacterSlot>.from(beat.characterSlots);

          for (final idx in interaction.sourceCharacterIndices) {
            if (idx < updatedSlots.length) {
              final tag = interaction.type == InteractionType.mutual
                  ? 'mutual#${interaction.actionName}'
                  : 'source#${interaction.actionName}';
              updatedSlots[idx] = _appendActionTag(updatedSlots[idx], tag);
            }
          }
          for (final idx in interaction.targetCharacterIndices) {
            if (idx < updatedSlots.length) {
              updatedSlots[idx] = _appendActionTag(
                  updatedSlots[idx], 'target#${interaction.actionName}');
            }
          }

          notifier.updateActiveBeat(beat.copyWith(characterSlots: updatedSlots));
        },
        onDelete: () {
          // Deletion is handled per-tag from the slot's action chips.
        },
      ),
    );
  }

  /// Appends [tag] to a slot's action tags, de-duplicating so re-linking the
  /// same action does not stack identical entries.
  BeatCharacterSlot _appendActionTag(BeatCharacterSlot slot, String tag) {
    if (slot.actionTags.contains(tag)) return slot;
    return slot.copyWith(actionTags: [...slot.actionTags, tag]);
  }

  /// A single removable action-tag chip for a character slot. Tapping the
  /// close icon removes only that tag, leaving any others intact.
  Widget _buildActionChip(BuildContext context, CascadeBeat beat,
      CascadeNotifier notifier, int index, BeatCharacterSlot slot, String tag) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.accentCascade.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: t.accentCascade.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 12, color: t.accentCascade),
          const SizedBox(width: 8),
          Text(
            tag.toUpperCase(),
            style: TextStyle(color: t.accentCascade, fontSize: t.fontSize(9), fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              final updatedSlots = List<BeatCharacterSlot>.from(beat.characterSlots);
              updatedSlots[index] = slot.copyWith(
                actionTags: slot.actionTags.where((e) => e != tag).toList(),
              );
              notifier.updateActiveBeat(beat.copyWith(characterSlots: updatedSlots));
            },
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(Icons.close, size: 12, color: t.accentCascade),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeatSettings(CascadeBeat beat, CascadeNotifier notifier) {
    final resValue = '${beat.width}x${beat.height}';
    final resOptions = AdvancedSettingsPanel.resolutionOptions(context);
    final knownRes = resOptions.any((opt) => opt.value == resValue);

    final l = context.l;
    return Column(
      children: [
        _buildCompactDropdown(
          label: l.cascadeResolution,
          value: knownRes ? resValue : resOptions.first.value,
          items: [...resOptions.map((opt) => opt.value), '__custom__'],
          itemLabels: [...resOptions.map((opt) => opt.displayLabel), '+ ${l.resCustomEntry.toUpperCase()}'],
          onChanged: (val) async {
            if (val == '__custom__') {
              final result = await showCustomResolutionDialog(context);
              if (result != null) {
                notifier.updateActiveBeat(beat.copyWith(
                  width: result.width,
                  height: result.height,
                ));
                if (mounted) setState(() {});
              }
              return;
            }
            if (val == null) return;
            final parts = val.split('x');
            notifier.updateActiveBeat(beat.copyWith(
              width: int.parse(parts[0]),
              height: int.parse(parts[1]),
            ));
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactDropdown(
                label: l.cascadeSampler,
                value: beat.sampler,
                items: ['k_euler_ancestral', 'k_euler', 'k_dpmpp_2s_ancestral', 'k_dpmpp_2m', 'k_dpmpp_sde'],
                onChanged: (val) => notifier.updateActiveBeat(beat.copyWith(sampler: val)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactValueAdjuster(
                label: l.cascadeSteps,
                value: beat.steps.toDouble(),
                min: 1,
                max: 50,
                onChanged: (val) => notifier.updateActiveBeat(beat.copyWith(steps: val.toInt())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactValueAdjuster(
                label: l.cascadeScale,
                value: beat.scale,
                min: 1.0,
                max: 30.0,
                onChanged: (val) => notifier.updateActiveBeat(beat.copyWith(scale: val)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStyleSelector(CascadeBeat beat, CascadeNotifier notifier) {
    final t = context.t;
    final l = context.l;
    final styles = context.read<GenerationNotifier>().state.styles;

    if (styles.isEmpty) {
      return Text(l.cascadeNoStyles, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9)));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: styles.map((style) {
        final isSelected = beat.activeStyleNames.contains(style.name);
        return FilterChip(
          selected: isSelected,
          label: Text(
            style.name.toUpperCase(),
            style: TextStyle(
              color: isSelected ? t.background : t.textSecondary,
              fontSize: t.fontSize(9),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 1,
            ),
          ),
          selectedColor: t.accentCascade,
          backgroundColor: t.borderSubtle,
          checkmarkColor: t.background,
          side: BorderSide(color: isSelected ? t.accentCascade : t.borderMedium),
          onSelected: (selected) {
            final updated = List<String>.from(beat.activeStyleNames);
            if (selected) {
              updated.add(style.name);
            } else {
              updated.remove(style.name);
            }
            notifier.updateActiveBeat(beat.copyWith(activeStyleNames: updated));
          },
        );
      }).toList(),
    );
  }

  Widget _buildCompactDropdown({required String label, required String value, required List<String> items, List<String>? itemLabels, required ValueChanged<String?> onChanged}) {
    final t = context.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: t.borderSubtle,
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: t.surfaceHigh,
            style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10)),
            items: List.generate(items.length, (i) => DropdownMenuItem(
              value: items[i],
              child: Text(itemLabels != null ? itemLabels[i] : items[i]),
            )),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactValueAdjuster({required String label, required double value, required double min, required double max, required ValueChanged<double> onChanged}) {
    final t = context.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(8), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: t.borderSubtle,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(value.toStringAsFixed(1), style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(10), fontWeight: FontWeight.bold)),
               Row(
                 children: [
                    InkWell(onTap: () => onChanged((value - 1).clamp(min, max)), child: Icon(Icons.remove, size: 14, color: t.textDisabled)),
                    const SizedBox(width: 8),
                    InkWell(onTap: () => onChanged((value + 1).clamp(min, max)), child: Icon(Icons.add, size: 14, color: t.textDisabled)),
                 ],
               )
            ],
          ),
        ),
      ],
    );
  }
}
