import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/models/nai_model.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/vision_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/tag_suggestion_helper.dart';
import '../../../../core/utils/tag_suggestion_keyboard.dart';
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
  // Keyed by the slot's castIndex, not its position in the beat: the
  // ReorderableListView keys its items by cast identity too, so when a slot is
  // dragged its (possibly focused) controller travels with it instead of
  // staying behind under whichever character now sits at that index.
  final Map<int, TextEditingController> _posControllers = {};
  final Map<int, TextEditingController> _negControllers = {};
  final Map<int, FocusNode> _posFocusNodes = {};
  final Map<int, FocusNode> _negFocusNodes = {};
  int? _lastBeatIndex;

  // Tag suggestion state
  List<DanbooruTag> _suggestions = [];
  final TagSuggestionKeyboard _suggestionKeys = TagSuggestionKeyboard();
  Timer? _debounce;
  TextEditingController? _activeSuggestionController;
  ValueChanged<String>? _activeSuggestionOnChanged;

  @override
  void initState() {
    super.initState();
    _sceneFocusNode.addListener(_onFocusChanged);
    _envFocusNode.addListener(_onFocusChanged);
    _attachPromptKeys(_sceneFocusNode);
    _attachPromptKeys(_envFocusNode);
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
    // Clear suggestions when all prompt fields lose focus. The overlay is a
    // TextFieldTapRegion, so tapping a chip does not count as tapping outside
    // the field and never triggers this path.
    Future.microtask(() {
      if (!mounted) return;
      final anyFocused =
          _sceneFocusNode.hasFocus ||
          _envFocusNode.hasFocus ||
          _posFocusNodes.values.any((f) => f.hasFocus) ||
          _negFocusNodes.values.any((f) => f.hasFocus);
      if (!anyFocused && _suggestions.isNotEmpty) {
        setState(() {
          _suggestions = [];
          _suggestionKeys.reset();
        });
      }
    });
  }

  void _handleTagInput(
    TextEditingController controller,
    ValueChanged<String> onChanged,
    String value,
    TagService? tagService,
  ) {
    onChanged(value);
    _activeSuggestionController = controller;
    _activeSuggestionOnChanged = onChanged;
    if (_suggestionKeys.selectedIndex != -1) {
      _suggestionKeys.reset();
    }
    _debounce?.cancel();
    if (tagService == null) {
      setState(() {
        _suggestions = [];
        _suggestionKeys.reset();
      });
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
      setState(() {
        _suggestions = result.suggestions;
        _suggestionKeys.reset();
      });
    });
  }

  void _onTagSelected(DanbooruTag tag) {
    if (_activeSuggestionController == null) return;
    TagSuggestionHelper.applyTag(_activeSuggestionController!, tag);
    _activeSuggestionOnChanged?.call(_activeSuggestionController!.text);
    setState(() {
      _suggestions = [];
      _suggestionKeys.reset();
    });
  }

  /// Same bindings as the main prompt: Tab / Shift+Tab cycle the overlay,
  /// Enter inserts the highlighted chip. With no suggestions, Tab still
  /// moves to the next field.
  KeyEventResult _onPromptKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final handled = _suggestionKeys.cycle(
        suggestionCount: _suggestions.length,
        reverse: HardwareKeyboard.instance.isShiftPressed,
      );
      if (handled) setState(() {});
      return handled ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final tag = _suggestionKeys.accept(_suggestions);
      if (tag != null) {
        _onTagSelected(tag);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _attachPromptKeys(FocusNode node) {
    node.onKeyEvent = _onPromptKeyEvent;
  }

  void _ensureSlotControllers(CascadeBeat beat) {
    for (final slot in beat.characterSlots) {
      final i = slot.castIndex;
      _posControllers.putIfAbsent(i, () => TextEditingController());
      _negControllers.putIfAbsent(i, () => TextEditingController());
      if (!_posFocusNodes.containsKey(i)) {
        final fn = FocusNode();
        fn.addListener(_onFocusChanged);
        _attachPromptKeys(fn);
        _posFocusNodes[i] = fn;
      }
      if (!_negFocusNodes.containsKey(i)) {
        final fn = FocusNode();
        fn.addListener(_onFocusChanged);
        _attachPromptKeys(fn);
        _negFocusNodes[i] = fn;
      }
    }
  }

  void _assignIfChanged(TextEditingController controller, String value) {
    if (controller.text != value) controller.text = value;
  }

  void _syncControllers(CascadeBeat beat, int beatIndex) {
    _ensureSlotControllers(beat);
    final beatChanged = _lastBeatIndex != beatIndex;
    _lastBeatIndex = beatIndex;

    if (beatChanged) {
      // A programmatic `.text =` below resets the field's selection, and on
      // touch platforms the field may still hold focus, so chips computed for
      // the previous beat's text would otherwise linger and insert into the
      // new beat's prompt. Drop them here (we are inside build; no setState).
      _suggestions = [];
      _activeSuggestionController = null;
      _activeSuggestionOnChanged = null;
      _debounce?.cancel();
    }

    if (beatChanged || !_sceneFocusNode.hasFocus) {
      _assignIfChanged(_sceneController, beat.sceneTags);
    }
    if (beatChanged || !_envFocusNode.hasFocus) {
      _assignIfChanged(_envController, beat.environmentTags);
    }
    for (final slot in beat.characterSlots) {
      final i = slot.castIndex;
      if (beatChanged || !_posFocusNodes[i]!.hasFocus) {
        _assignIfChanged(_posControllers[i]!, slot.positivePrompt);
      }
      if (beatChanged || !_negFocusNodes[i]!.hasFocus) {
        _assignIfChanged(_negControllers[i]!, slot.negativePrompt);
      }
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
          return Center(
            child: Text(
              l.cascadeNoBeatSelected,
              style: TextStyle(
                color: t.textDisabled,
                fontSize: t.fontSize(10),
                letterSpacing: 2,
              ),
            ),
          );
        }

        final beatIndex = state.selectedBeatIndex!;
        final beat = state.activeCascade!.beats[beatIndex];
        final useCoords = state.activeCascade!.effectiveUseCoords(beat);

        _syncControllers(beat, beatIndex);

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
                onChanged: (v) =>
                    notifier.updateActiveBeat(beat.copyWith(sceneTags: v)),
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
                onChanged: (v) => notifier.updateActiveBeat(
                  beat.copyWith(environmentTags: v),
                ),
                tagService: tagService,
              ),
              const SizedBox(height: 32),
              _buildCharacterSlotsHeader(l, t, beat, notifier, useCoords),
              const SizedBox(height: 16),
              if (beat.characterSlots.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l.cascadeNoCharactersInBeat,
                    style: TextStyle(
                      color: t.textDisabled,
                      fontSize: t.fontSize(10),
                    ),
                  ),
                )
              else
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: notifier.reorderCharactersInActiveBeat,
                  children: [
                    for (int i = 0; i < beat.characterSlots.length; i++)
                      KeyedSubtree(
                        key: ValueKey(
                          'cascade-slot-${beat.characterSlots[i].castIndex}',
                        ),
                        child: _buildSlotItem(
                          context,
                          i,
                          beat,
                          notifier,
                          useCoords,
                          dragHandle: ReorderableDragStartListener(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.drag_handle,
                                size: 18,
                                color: t.textDisabled,
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildCharacterSlotsHeader(
    AppLocalizations l,
    VisionTokens t,
    CascadeBeat beat,
    CascadeNotifier notifier,
    bool useCoords,
  ) {
    final slotCount = beat.characterSlots.length;
    final castCount = notifier.state.activeCascade?.characterCount ?? 0;
    final missing = notifier.castMembersMissingFromActiveBeat();
    // The active model decides how many characters a render may carry
    // (6 on V4.5, 32 on V5); the request builder truncates beyond that.
    final maxSlots = context
        .read<GenerationNotifier>()
        .state
        .model
        .maxCharacters;
    final canAddNew = castCount < maxSlots;
    final canAdd = slotCount < maxSlots && (missing.isNotEmpty || canAddNew);
    final menuStyle = TextStyle(
      color: t.textPrimary,
      fontSize: t.fontSize(10),
      letterSpacing: 1,
    );
    return Row(
      children: [
        Expanded(child: _buildSectionHeader(l.cascadeCharacterSlots)),
        _placementToggle(l, t, useCoords, notifier),
        const SizedBox(width: 8),
        // Existing cast members who are absent from this beat come first so
        // "C2 alone in this shot" is one tap; a fresh character is last.
        PopupMenuButton<int>(
          tooltip: l.cascadeAddCharacter,
          enabled: canAdd,
          color: t.surfaceHigh,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 160),
          onSelected: (v) => notifier.addCharacterToActiveBeat(
            castIndex: v < 0 ? null : v,
            maxSlots: maxSlots,
          ),
          itemBuilder: (_) => [
            for (final i in missing)
              PopupMenuItem<int>(
                value: i,
                height: 36,
                child: Text(l.cascadeCastMemberN(i + 1), style: menuStyle),
              ),
            if (canAddNew)
              PopupMenuItem<int>(
                value: -1,
                height: 36,
                child: Text(l.cascadeNewCharacter, style: menuStyle),
              ),
          ],
          child: Icon(
            Icons.person_add_alt_1,
            size: 18,
            color: canAdd ? t.accentCascade : t.textMinimal,
          ),
        ),
      ],
    );
  }

  Widget _placementToggle(
    AppLocalizations l,
    VisionTokens t,
    bool useCoords,
    CascadeNotifier notifier,
  ) {
    Widget pill(String label, bool selected, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? t.accentCascade.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? t.accentCascade : t.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? t.accentCascade : t.textDisabled,
              fontSize: t.fontSize(8),
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill(
          l.cascadePlacementManual,
          useCoords,
          () => notifier.setActiveBeatUseCoords(true),
        ),
        const SizedBox(width: 4),
        pill(
          l.cascadePlacementAi,
          !useCoords,
          () => notifier.setActiveBeatUseCoords(false),
        ),
      ],
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
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
        if (subLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subLabel,
              style: TextStyle(
                color: t.textDisabled,
                fontSize: t.fontSize(8),
                letterSpacing: 0.5,
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (val) =>
              _handleTagInput(controller, onChanged, val, tagService),
          style: TextStyle(
            color: t.textPrimary,
            fontSize: t.fontSize(13),
            height: 1.4,
          ),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: t.textMinimal,
              fontSize: t.fontSize(11),
            ),
            filled: true,
            fillColor: t.accentCascade.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: t.accentCascade.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: t.accentCascade.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: t.accentCascade.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
        if (_activeSuggestionController == controller &&
            _suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TagSuggestionOverlay(
              suggestions: _suggestions,
              onTagSelected: _onTagSelected,
              selectedIndex: _suggestionKeys.selectedIndex,
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

  Widget _buildSlotItem(
    BuildContext context,
    int index,
    CascadeBeat beat,
    CascadeNotifier notifier,
    bool useCoords, {
    Widget? dragHandle,
  }) {
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
              if (dragHandle != null) dragHandle,
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.accentCascade,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${slot.castIndex + 1}',
                  style: TextStyle(
                    color: t.background,
                    fontWeight: FontWeight.bold,
                    fontSize: t.fontSize(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l.cascadeCastMemberN(slot.castIndex + 1),
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: t.fontSize(11),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (beat.characterSlots.length >= 2)
                _buildActionLinker(context, index, beat, notifier),
              IconButton(
                tooltip: l.cascadeRemoveCharacter,
                onPressed: () => notifier.removeCharacterFromActiveBeat(index),
                icon: Icon(
                  Icons.person_remove_alt_1,
                  size: 18,
                  color: t.textDisabled,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
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
                      Text(
                        l.cascadePosition,
                        style: TextStyle(
                          color: t.textDisabled,
                          fontSize: t.fontSize(8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final ratio = beat.height > 0
                              ? beat.width / beat.height
                              : 1.0;
                          var width = constraints.maxWidth;
                          var height = width / ratio;
                          const maxH = 240.0;
                          const minH = 120.0;
                          if (height > maxH) {
                            height = maxH;
                            width = height * ratio;
                          } else if (height < minH) {
                            height = minH;
                            width = height * ratio;
                            if (width > constraints.maxWidth) {
                              width = constraints.maxWidth;
                              height = width / ratio;
                            }
                          }
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: NaiGridSelector(
                                freeform: context
                                    .select<GenerationNotifier?, bool>(
                                      (n) =>
                                          n
                                              ?.state
                                              .model
                                              .caps
                                              .freeformPosition ??
                                          false,
                                    ),
                                aspectRatio: ratio,
                                selectedCoordinate: slot.position,
                                onCoordinateSelected: (coord) {
                                  final updatedSlots =
                                      List<BeatCharacterSlot>.from(
                                        beat.characterSlots,
                                      );
                                  updatedSlots[index] = slot.copyWith(
                                    position: coord,
                                  );
                                  notifier.updateActiveBeat(
                                    beat.copyWith(characterSlots: updatedSlots),
                                  );
                                },
                              ),
                            ),
                          );
                        },
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
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
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
                      controller: _posControllers[slot.castIndex]!,
                      focusNode: _posFocusNodes[slot.castIndex]!,
                      onChanged: (val) {
                        final updatedSlots = List<BeatCharacterSlot>.from(
                          beat.characterSlots,
                        );
                        updatedSlots[index] = slot.copyWith(
                          positivePrompt: val,
                        );
                        notifier.updateActiveBeat(
                          beat.copyWith(characterSlots: updatedSlots),
                        );
                      },
                      tagService: generationNotifier.tagService,
                    ),
                    const SizedBox(height: 16),
                    _buildPromptField(
                      label: l.cascadeNegativePrompt,
                      hint: l.cascadeAvoidHint,
                      controller: _negControllers[slot.castIndex]!,
                      focusNode: _negFocusNodes[slot.castIndex]!,
                      onChanged: (val) {
                        final updatedSlots = List<BeatCharacterSlot>.from(
                          beat.characterSlots,
                        );
                        updatedSlots[index] = slot.copyWith(
                          negativePrompt: val,
                        );
                        notifier.updateActiveBeat(
                          beat.copyWith(characterSlots: updatedSlots),
                        );
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
        Text(
          label,
          style: TextStyle(
            color: t.textDisabled,
            fontSize: t.fontSize(8),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (val) =>
              _handleTagInput(controller, onChanged, val, tagService),
          maxLines: 2,
          style: TextStyle(
            color: t.textPrimary,
            fontSize: t.fontSize(11),
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
            filled: true,
            fillColor: t.background.withValues(alpha: 0.2),
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: t.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: t.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: t.accentCascade.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
        if (_activeSuggestionController == controller &&
            _suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TagSuggestionOverlay(
              suggestions: _suggestions,
              onTagSelected: _onTagSelected,
              selectedIndex: _suggestionKeys.selectedIndex,
            ),
          ),
      ],
    );
  }

  Widget _buildActionLinker(
    BuildContext context,
    int index,
    CascadeBeat beat,
    CascadeNotifier notifier,
  ) {
    final t = context.t;
    final l = context.l;
    return IconButton(
      icon: Icon(Icons.link, size: 18, color: t.accentCascade),
      onPressed: () {
        _showLinkerMenu(context, index, beat, notifier);
      },
      tooltip: l.cascadeLinkAction,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: const EdgeInsets.all(6),
    );
  }

  void _showLinkerMenu(
    BuildContext context,
    int sourceIndex,
    CascadeBeat beat,
    CascadeNotifier notifier,
  ) {
    final t = context.tRead;
    final targetIndex = (sourceIndex + 1) % beat.characterSlots.length;
    // Build dummy character list for the sheet's label display
    final sheetChars = beat.characterSlots
        .asMap()
        .entries
        .map(
          (e) => NaiCharacter(
            prompt: '',
            uc: '',
            center: NaiCoordinate(x: 0.5, y: 0.5),
            name: 'C${e.value.castIndex + 1}',
          ),
        )
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surfaceMid,
      builder: (context) => ActionInteractionSheet(
        sourceIndices: [sourceIndex],
        targetIndices: [targetIndex],
        initialType: InteractionType.sourceTarget,
        anchorIndex: sourceIndex,
        characters: sheetChars,
        onSave: (interaction) {
          final updatedSlots = List<BeatCharacterSlot>.from(
            beat.characterSlots,
          );

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
                updatedSlots[idx],
                'target#${interaction.actionName}',
              );
            }
          }

          notifier.updateActiveBeat(
            beat.copyWith(characterSlots: updatedSlots),
          );
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
  Widget _buildActionChip(
    BuildContext context,
    CascadeBeat beat,
    CascadeNotifier notifier,
    int index,
    BeatCharacterSlot slot,
    String tag,
  ) {
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
            style: TextStyle(
              color: t.accentCascade,
              fontSize: t.fontSize(9),
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              final updatedSlots = List<BeatCharacterSlot>.from(
                beat.characterSlots,
              );
              updatedSlots[index] = slot.copyWith(
                actionTags: slot.actionTags.where((e) => e != tag).toList(),
              );
              notifier.updateActiveBeat(
                beat.copyWith(characterSlots: updatedSlots),
              );
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
          itemLabels: [
            ...resOptions.map((opt) => opt.displayLabel),
            '+ ${l.resCustomEntry.toUpperCase()}',
          ],
          onChanged: (val) async {
            if (val == '__custom__') {
              final result = await showCustomResolutionDialog(context);
              if (result != null) {
                notifier.updateActiveBeat(
                  beat.copyWith(width: result.width, height: result.height),
                );
                if (mounted) setState(() {});
              }
              return;
            }
            if (val == null) return;
            final parts = val.split('x');
            notifier.updateActiveBeat(
              beat.copyWith(
                width: int.parse(parts[0]),
                height: int.parse(parts[1]),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactDropdown(
                label: l.cascadeSampler,
                value: beat.sampler,
                items: [
                  'k_euler_ancestral',
                  'k_euler',
                  'k_dpmpp_2s_ancestral',
                  'k_dpmpp_2m',
                  'k_dpmpp_sde',
                ],
                onChanged: (val) =>
                    notifier.updateActiveBeat(beat.copyWith(sampler: val)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactValueAdjuster(
                label: l.cascadeSteps,
                value: beat.steps.toDouble(),
                min: 1,
                max: 50,
                onChanged: (val) => notifier.updateActiveBeat(
                  beat.copyWith(steps: val.toInt()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactValueAdjuster(
                label: l.cascadeScale,
                value: beat.scale,
                min: 1.0,
                max: 30.0,
                onChanged: (val) =>
                    notifier.updateActiveBeat(beat.copyWith(scale: val)),
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
    final gen = context.read<GenerationNotifier>();
    // Beats render with the main editor's model, so offer the same subset.
    final styles = gen.stylesForCurrentModel;
    final hiddenCount = gen.hiddenStyleCountForCurrentModel;
    final otherFamily = gen.state.model.isV5
        ? NaiModelFamily.v45
        : NaiModelFamily.v5;

    if (styles.isEmpty) {
      return Text(
        l.cascadeNoStyles,
        style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
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
              side: BorderSide(
                color: isSelected ? t.accentCascade : t.borderMedium,
              ),
              onSelected: (selected) {
                final updated = List<String>.from(beat.activeStyleNames);
                if (selected) {
                  updated.add(style.name);
                } else {
                  updated.remove(style.name);
                }
                notifier.updateActiveBeat(
                  beat.copyWith(activeStyleNames: updated),
                );
              },
            );
          }).toList(),
        ),
        if (hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.panelStylesHidden(hiddenCount, otherFamily.label),
              style: TextStyle(color: t.textMinimal, fontSize: t.fontSize(8)),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required String value,
    required List<String> items,
    List<String>? itemLabels,
    required ValueChanged<String?> onChanged,
  }) {
    final t = context.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: t.textDisabled,
            fontSize: t.fontSize(8),
            fontWeight: FontWeight.bold,
          ),
        ),
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
            items: List.generate(
              items.length,
              (i) => DropdownMenuItem(
                value: items[i],
                child: Text(itemLabels != null ? itemLabels[i] : items[i]),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactValueAdjuster({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final t = context.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: t.textDisabled,
            fontSize: t.fontSize(8),
            fontWeight: FontWeight.bold,
          ),
        ),
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
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: t.fontSize(10),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => onChanged((value - 1).clamp(min, max)),
                    child: Icon(Icons.remove, size: 14, color: t.textDisabled),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => onChanged((value + 1).clamp(min, max)),
                    child: Icon(Icons.add, size: 14, color: t.textDisabled),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
