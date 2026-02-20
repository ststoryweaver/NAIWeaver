import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/tag_suggestion_overlay.dart';
import '../../../tag_service.dart';
import '../models/nai_character.dart';
import '../models/character_preset.dart';
import '../providers/generation_notifier.dart';
import 'nai_grid_selector.dart';
import 'action_interaction_sheet.dart';

class _CharEditorState {
  final List<NaiCharacter> characters;
  final List<NaiInteraction> interactions;
  final bool autoPositioning;
  final String characterEditorMode;
  final List<CharacterPreset> characterPresets;

  const _CharEditorState({
    required this.characters,
    required this.interactions,
    required this.autoPositioning,
    required this.characterEditorMode,
    required this.characterPresets,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CharEditorState &&
          listEquals(characters, other.characters) &&
          listEquals(interactions, other.interactions) &&
          autoPositioning == other.autoPositioning &&
          characterEditorMode == other.characterEditorMode &&
          listEquals(characterPresets, other.characterPresets);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(characters),
        Object.hashAll(interactions),
        autoPositioning,
        characterEditorMode,
        Object.hashAll(characterPresets),
      );
}

class InlineCharacterEditor extends StatelessWidget {
  const InlineCharacterEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<GenerationNotifier, _CharEditorState>(
      selector: (_, n) => _CharEditorState(
        characters: n.state.characters,
        interactions: n.state.interactions,
        autoPositioning: n.state.autoPositioning,
        characterEditorMode: n.state.characterEditorMode,
        characterPresets: n.state.characterPresets,
      ),
      shouldRebuild: (prev, next) => prev != next,
      builder: (context, editorState, _) {
        final notifier = context.read<GenerationNotifier>();
        final t = context.t;
        final l = context.l;
        final mobile = isMobile(context);
        final labelStyle = TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: t.fontSize(mobile ? 12 : 9),
          letterSpacing: 2,
          color: t.secondaryText,
        );

        final mode = editorState.characterEditorMode;
        final isExpanded = mode == 'expanded';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: label + mode chips + auto chip
            Row(
              children: [
                Flexible(
                  child: Text(l.charEditorTitle.toUpperCase(), style: labelStyle),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: l.charEditorExpanded,
                  isSelected: isExpanded,
                  onTap: () => notifier.setCharacterEditorMode('expanded'),
                  t: t,
                  mobile: mobile,
                ),
                const SizedBox(width: 4),
                _ModeChip(
                  label: l.charEditorCompact,
                  isSelected: !isExpanded,
                  onTap: () => notifier.setCharacterEditorMode('compact'),
                  t: t,
                  mobile: mobile,
                ),
                if (isExpanded && editorState.characters.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _ModeChip(
                    label: l.charEditorAutoPosition,
                    isSelected: editorState.autoPositioning,
                    onTap: () => notifier.setAutoPositioning(!editorState.autoPositioning),
                    t: t,
                    accentColor: Colors.orange,
                    mobile: mobile,
                  ),
                ],
              ],
            ),

            if (!isExpanded) ...[
              const SizedBox(height: 8),
              Text(
                l.charEditorUsingCompactShelf.toUpperCase(),
                style: TextStyle(
                  fontSize: t.fontSize(mobile ? 9 : 8),
                  color: t.textMinimal,
                  letterSpacing: 1,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            if (isExpanded) ...[
              const SizedBox(height: 12),
              // Character cards
              for (int i = 0; i < editorState.characters.length; i++) ...[
                _CharacterCard(
                  key: ValueKey('char_$i'),
                  index: i,
                  character: editorState.characters[i],
                  autoPositioning: editorState.autoPositioning,
                  characterPresets: editorState.characterPresets,
                ),
                if (i < editorState.characters.length - 1) const SizedBox(height: 8),
              ],

              // Add character button
              if (editorState.characters.length < 6) ...[
                const SizedBox(height: 8),
                _AddCharacterButton(
                  onTap: () => notifier.addCharacter(),
                  label: l.charEditorAddCharacter,
                  t: t,
                ),
              ],

              // Interactions section
              if (editorState.characters.length >= 2) ...[
                const SizedBox(height: 16),
                Divider(color: t.borderSubtle, height: 1),
                const SizedBox(height: 12),
                _InteractionsSection(
                  characters: editorState.characters,
                  interactions: editorState.interactions,
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

// ─── Mode Chip ───────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VisionTokens t;
  final Color? accentColor;
  final bool mobile;

  const _ModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.t,
    this.accentColor,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? t.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 12 : 8,
          vertical: mobile ? 8 : 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : t.borderSubtle,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? color : t.textMinimal,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: t.fontSize(mobile ? 10 : 8),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: isSelected ? t.background : t.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ─── Add Character Button ────────────────────────────────────────────────────

class _AddCharacterButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final VisionTokens t;

  const _AddCharacterButton({
    required this.onTap,
    required this.label,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: t.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 14, color: t.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: t.fontSize(9),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: t.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Character Card ──────────────────────────────────────────────────────────

class _CharacterCard extends StatefulWidget {
  final int index;
  final NaiCharacter character;
  final bool autoPositioning;
  final List<CharacterPreset> characterPresets;

  const _CharacterCard({
    super.key,
    required this.index,
    required this.character,
    required this.autoPositioning,
    required this.characterPresets,
  });

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard> {
  late TextEditingController _nameController;
  late TextEditingController _promptController;
  late TextEditingController _ucController;

  List<DanbooruTag> _promptSuggestions = [];
  List<DanbooruTag> _ucSuggestions = [];

  Timer? _debounce;
  bool _syncing = false;
  bool _isCollapsed = false;
  bool _showUc = false;
  bool _showPosition = false;
  bool _showPresets = false;

  TagService? _tagService;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character.name);
    _promptController = TextEditingController(text: widget.character.prompt);
    _ucController = TextEditingController(text: widget.character.uc);

    _nameController.addListener(_onTextChanged);
    _promptController.addListener(_onPromptChanged);
    _ucController.addListener(_onUcChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tagService ??= context.read<GenerationNotifier>().tagService;
  }

  @override
  void didUpdateWidget(covariant _CharacterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromExternal(oldWidget);
  }

  void _syncFromExternal(_CharacterCard oldWidget) {
    // Only sync if the data changed from an external source (preset apply, session restore)
    // and not from our own controller edits
    if (_syncing) return;

    final oldChar = oldWidget.character;
    final newChar = widget.character;

    bool changed = false;
    if (oldChar.name != newChar.name && _nameController.text != newChar.name) {
      changed = true;
    }
    if (oldChar.prompt != newChar.prompt && _promptController.text != newChar.prompt) {
      changed = true;
    }
    if (oldChar.uc != newChar.uc && _ucController.text != newChar.uc) {
      changed = true;
    }

    if (changed) {
      _syncing = true;
      if (_nameController.text != newChar.name) _nameController.text = newChar.name;
      if (_promptController.text != newChar.prompt) _promptController.text = newChar.prompt;
      if (_ucController.text != newChar.uc) _ucController.text = newChar.uc;
      _syncing = false;
    }
  }

  void _onTextChanged() {
    if (_syncing) return;
    _scheduleSave();
  }

  void _onPromptChanged() {
    if (_syncing) return;
    _scheduleSave();
    _updatePromptSuggestions();
  }

  void _onUcChanged() {
    if (_syncing) return;
    _scheduleSave();
    _updateUcSuggestions();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _syncing = true;
      final notifier = context.read<GenerationNotifier>();
      notifier.updateCharacter(
        widget.index,
        widget.character.copyWith(
          name: _nameController.text,
          prompt: _promptController.text,
          uc: _ucController.text,
        ),
      );
      _syncing = false;
    });
  }

  void _updatePromptSuggestions() {
    if (!mounted || _tagService == null) return;
    final text = _promptController.text;
    if (text.isEmpty) {
      if (_promptSuggestions.isNotEmpty) setState(() => _promptSuggestions = []);
      return;
    }
    final parts = text.split(',');
    final lastPart = parts.last.trim();
    if (lastPart.length < 2) {
      if (_promptSuggestions.isNotEmpty) setState(() => _promptSuggestions = []);
      return;
    }
    final suggestions = _tagService!.getSuggestions(lastPart);
    setState(() => _promptSuggestions = suggestions);
  }

  void _updateUcSuggestions() {
    if (!mounted || _tagService == null) return;
    final text = _ucController.text;
    if (text.isEmpty) {
      if (_ucSuggestions.isNotEmpty) setState(() => _ucSuggestions = []);
      return;
    }
    final parts = text.split(',');
    final lastPart = parts.last.trim();
    if (lastPart.length < 2) {
      if (_ucSuggestions.isNotEmpty) setState(() => _ucSuggestions = []);
      return;
    }
    final suggestions = _tagService!.getSuggestions(lastPart);
    setState(() => _ucSuggestions = suggestions);
  }

  void _onTagSelected(TextEditingController controller, DanbooruTag tag) {
    final currentText = controller.text;
    final parts = currentText.split(',');
    parts.removeLast();
    final newText = parts.isEmpty
        ? '${tag.tag}, '
        : '${parts.join(',')}, ${tag.tag}, ';
    controller.text = newText;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );
  }

  void _confirmDelete(BuildContext context) {
    final notifier = context.read<GenerationNotifier>();
    final t = context.tRead;
    final l = context.l;
    final name = widget.character.name.isNotEmpty
        ? widget.character.name
        : l.charEditorCharacterN(widget.index + 1);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(
          l.charEditorDeleteCharacter.toUpperCase(),
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(12), fontWeight: FontWeight.bold),
        ),
        content: Text(
          l.charEditorDeleteConfirm(name),
          style: TextStyle(color: t.textSecondary, fontSize: t.fontSize(11)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10))),
          ),
          TextButton(
            onPressed: () {
              notifier.removeCharacter(widget.index);
              Navigator.pop(ctx);
            },
            child: Text(l.commonDelete.toUpperCase(), style: TextStyle(color: t.accentDanger, fontSize: t.fontSize(10), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _saveAsPreset(BuildContext context) {
    final notifier = context.read<GenerationNotifier>();
    final t = context.tRead;
    final l = context.l;
    final nameCtrl = TextEditingController(text: widget.character.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surfaceHigh,
        title: Text(l.charEditorSavePreset, style: TextStyle(fontSize: t.fontSize(10), letterSpacing: 2, color: t.textSecondary)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(13)),
          decoration: InputDecoration(
            hintText: l.charEditorPresetName.toUpperCase(),
            hintStyle: TextStyle(color: t.textMinimal, fontSize: t.fontSize(9)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.borderMedium)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel.toUpperCase(), style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(9))),
          ),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                notifier.saveCharacterPreset(CharacterPreset(
                  id: 'cp_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text,
                  prompt: _promptController.text,
                  uc: _ucController.text,
                ));
                Navigator.pop(ctx);
              }
            },
            child: Text(l.commonSave.toUpperCase(), style: TextStyle(color: t.accent, fontSize: t.fontSize(9))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.removeListener(_onTextChanged);
    _promptController.removeListener(_onPromptChanged);
    _ucController.removeListener(_onUcChanged);
    _nameController.dispose();
    _promptController.dispose();
    _ucController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);
    final subLabelStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: t.fontSize(mobile ? 10 : 8),
      letterSpacing: 2,
      color: t.textDisabled,
    );

    final displayName = widget.character.name.isNotEmpty
        ? widget.character.name.toUpperCase()
        : l.charEditorCharacterN(widget.index + 1).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: t.borderSubtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: t.borderMedium, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          InkWell(
            onTap: () => setState(() => _isCollapsed = !_isCollapsed),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _isCollapsed ? Icons.expand_more : Icons.expand_less,
                    size: 16,
                    color: t.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: t.fontSize(mobile ? 11 : 9),
                        letterSpacing: 2,
                        color: t.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(context),
                    icon: Icon(Icons.close, size: 14, color: t.textTertiary),
                    constraints: BoxConstraints(
                      minWidth: mobile ? 40 : 24,
                      minHeight: mobile ? 40 : 24,
                    ),
                    padding: EdgeInsets.all(mobile ? 8 : 0),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible body
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isCollapsed
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name field
                        Text(l.charEditorCharacterName, style: subLabelStyle),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: mobile ? double.infinity : 400,
                          child: TextField(
                            controller: _nameController,
                            maxLines: 1,
                            style: TextStyle(fontSize: t.fontSize(9), color: t.textSecondary),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: l.charEditorCharacterN(widget.index + 1).toUpperCase(),
                              hintStyle: TextStyle(fontSize: t.fontSize(9), color: t.textMinimal),
                              fillColor: t.surfaceHigh,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.borderMedium)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),

                        // Prompt field
                        const SizedBox(height: 10),
                        TextField(
                          controller: _promptController,
                          maxLines: 3,
                          minLines: 2,
                          style: TextStyle(fontSize: t.fontSize(11), color: t.textSecondary, height: 1.4),
                          decoration: InputDecoration(
                            hintText: l.charEditorPromptHint.toUpperCase(),
                            hintStyle: TextStyle(fontSize: t.fontSize(9), color: t.textMinimal),
                            fillColor: t.surfaceHigh,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.borderMedium)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        if (_promptSuggestions.isNotEmpty)
                          TagSuggestionOverlay(
                            suggestions: _promptSuggestions,
                            onTagSelected: (tag) => _onTagSelected(_promptController, tag),
                          ),

                        // Sub-section toggle chips
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _SubChip(
                              label: l.charEditorShowUc,
                              isSelected: _showUc,
                              onTap: () => setState(() => _showUc = !_showUc),
                              t: t,
                              mobile: mobile,
                            ),
                            _SubChip(
                              label: l.charEditorShowPosition,
                              isSelected: _showPosition,
                              onTap: () => setState(() => _showPosition = !_showPosition),
                              t: t,
                              mobile: mobile,
                            ),
                            _SubChip(
                              label: l.charEditorShowPresets,
                              isSelected: _showPresets,
                              onTap: () => setState(() => _showPresets = !_showPresets),
                              t: t,
                              mobile: mobile,
                            ),
                          ],
                        ),

                        // UC section
                        if (_showUc) ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: _ucController,
                            maxLines: 2,
                            minLines: 1,
                            style: TextStyle(fontSize: t.fontSize(11), color: t.textSecondary, height: 1.4),
                            decoration: InputDecoration(
                              hintText: l.charEditorUcHint.toUpperCase(),
                              hintStyle: TextStyle(fontSize: t.fontSize(9), color: t.textMinimal),
                              fillColor: t.surfaceHigh,
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.borderMedium)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          if (_ucSuggestions.isNotEmpty)
                            TagSuggestionOverlay(
                              suggestions: _ucSuggestions,
                              onTagSelected: (tag) => _onTagSelected(_ucController, tag),
                            ),
                        ],

                        // Position section
                        if (_showPosition) ...[
                          const SizedBox(height: 10),
                          if (widget.autoPositioning)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: Text(
                                l.charEditorAiDecidesPosition.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: t.fontSize(10),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            )
                          else
                            Center(
                              child: SizedBox(
                                height: 120,
                                width: 120,
                                child: NaiGridSelector(
                                  selectedCoordinate: widget.character.center,
                                  onCoordinateSelected: (coord) {
                                    final notifier = context.read<GenerationNotifier>();
                                    notifier.updateCharacter(
                                      widget.index,
                                      widget.character.copyWith(center: coord),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],

                        // Presets section
                        if (_showPresets) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ActionChip(
                                avatar: Icon(Icons.save_outlined, size: 14, color: t.textTertiary),
                                label: Text(
                                  l.charEditorSavePreset,
                                  style: TextStyle(fontSize: t.fontSize(8), fontWeight: FontWeight.bold, letterSpacing: 1, color: t.textTertiary),
                                ),
                                backgroundColor: t.borderSubtle,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                side: BorderSide(color: t.textMinimal, width: 0.5),
                                onPressed: () => _saveAsPreset(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (widget.characterPresets.isEmpty)
                            Text(
                              l.charEditorNoPresets.toUpperCase(),
                              style: TextStyle(fontSize: t.fontSize(8), color: t.textMinimal, letterSpacing: 1),
                            )
                          else
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: widget.characterPresets.map((preset) {
                                return GestureDetector(
                                  onLongPress: () {
                                    final notifier = context.read<GenerationNotifier>();
                                    notifier.deleteCharacterPreset(preset.id);
                                  },
                                  child: ActionChip(
                                    label: Text(
                                      preset.name.toUpperCase(),
                                      style: TextStyle(fontSize: t.fontSize(8), fontWeight: FontWeight.bold, letterSpacing: 1, color: t.textTertiary),
                                    ),
                                    backgroundColor: t.borderSubtle,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                    side: BorderSide(color: t.textMinimal, width: 0.5),
                                    onPressed: () {
                                      final notifier = context.read<GenerationNotifier>();
                                      notifier.applyCharacterPreset(widget.index, preset);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-section Toggle Chip ─────────────────────────────────────────────────

class _SubChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VisionTokens t;
  final bool mobile;

  const _SubChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.t,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 10 : 6,
          vertical: mobile ? 6 : 3,
        ),
        decoration: BoxDecoration(
          color: isSelected ? t.accent.withValues(alpha: 0.2) : t.surfaceHigh,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? t.accent : t.borderMedium,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: t.fontSize(mobile ? 9 : 7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: isSelected ? t.accent : t.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ─── Interactions Section ────────────────────────────────────────────────────

class _InteractionsSection extends StatelessWidget {
  final List<NaiCharacter> characters;
  final List<NaiInteraction> interactions;

  const _InteractionsSection({
    required this.characters,
    required this.interactions,
  });

  void _openInteractionEditor(BuildContext context, {
    required List<int> sourceIndices,
    required List<int> targetIndices,
    required InteractionType type,
    NaiInteraction? existing,
  }) {
    final notifier = context.read<GenerationNotifier>();
    final t = context.tRead;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surfaceHigh,
      builder: (context) => ActionInteractionSheet(
        sourceIndices: sourceIndices,
        targetIndices: targetIndices,
        initialType: type,
        characters: characters,
        initialInteraction: existing,
        onSave: (updated) => notifier.updateInteraction(updated, replacing: existing),
        onDelete: () {
          if (existing != null) notifier.removeInteraction(existing);
        },
      ),
    );
  }

  void _showAddInteractionPicker(BuildContext context) {
    final t = context.tRead;
    final l = context.l;
    var isMutual = false;
    final selectedSources = <int>{};
    final selectedTargets = <int>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surfaceHigh,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final chipStyle = TextStyle(
            fontSize: t.fontSize(9),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          );

          Widget buildCharChip(int i, Set<int> selected, {Set<int>? excluded}) {
            final name = characters[i].name.isNotEmpty
                ? characters[i].name
                : l.charEditorCharacterN(i + 1);
            final isSelected = selected.contains(i);
            final isExcluded = excluded?.contains(i) ?? false;
            return InkWell(
              onTap: isExcluded ? null : () {
                setSheetState(() {
                  if (isSelected) {
                    selected.remove(i);
                  } else {
                    selected.add(i);
                  }
                });
              },
              borderRadius: BorderRadius.circular(2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isExcluded
                      ? t.borderSubtle.withValues(alpha: 0.3)
                      : isSelected
                          ? t.accent
                          : t.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: isExcluded ? t.textMinimal.withValues(alpha: 0.3) : isSelected ? t.accent : t.textMinimal,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  name.toUpperCase(),
                  style: chipStyle.copyWith(
                    color: isExcluded
                        ? t.textMinimal.withValues(alpha: 0.3)
                        : isSelected
                            ? t.background
                            : t.textTertiary,
                  ),
                ),
              ),
            );
          }

          final bool canContinue;
          if (isMutual) {
            canContinue = selectedSources.length >= 2;
          } else {
            canContinue = selectedSources.isNotEmpty && selectedTargets.isNotEmpty;
          }

          return Container(
            color: t.surfaceMid,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 24,
              right: 24,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.charEditorAddInteraction.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: t.fontSize(12),
                    letterSpacing: 4,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                // Type selector chips
                Row(
                  children: [
                    InkWell(
                      onTap: () => setSheetState(() {
                        isMutual = false;
                        selectedTargets.clear();
                      }),
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: !isMutual ? t.accent : t.borderSubtle,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: !isMutual ? t.accent : t.textMinimal, width: 0.5),
                        ),
                        child: Text(
                          l.charEditorSourceTarget,
                          style: chipStyle.copyWith(color: !isMutual ? t.background : t.textTertiary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setSheetState(() {
                        isMutual = true;
                        selectedTargets.clear();
                      }),
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMutual ? t.accent : t.borderSubtle,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: isMutual ? t.accent : t.textMinimal, width: 0.5),
                        ),
                        child: Text(
                          l.charEditorMutual,
                          style: chipStyle.copyWith(color: isMutual ? t.background : t.textTertiary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isMutual) ...[
                  Text(l.charEditorParticipants.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(9), letterSpacing: 2, color: t.textDisabled)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(characters.length, (i) => buildCharChip(i, selectedSources)),
                  ),
                ] else ...[
                  Text(l.charEditorSelectSource.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(9), letterSpacing: 2, color: t.textDisabled)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(characters.length, (i) => buildCharChip(i, selectedSources, excluded: selectedTargets)),
                  ),
                  const SizedBox(height: 16),
                  Text(l.charEditorSelectTarget.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: t.fontSize(9), letterSpacing: 2, color: t.textDisabled)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(characters.length, (i) => buildCharChip(i, selectedTargets, excluded: selectedSources)),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: canContinue
                      ? () {
                          Navigator.pop(ctx);
                          _openInteractionEditor(
                            context,
                            sourceIndices: selectedSources.toList()..sort(),
                            targetIndices: isMutual ? [] : (selectedTargets.toList()..sort()),
                            type: isMutual ? InteractionType.mutual : InteractionType.sourceTarget,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: t.background,
                    disabledBackgroundColor: t.borderSubtle,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    l.charEditorContinue,
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: t.fontSize(10)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;
    final mobile = isMobile(context);
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: t.fontSize(mobile ? 10 : 8),
      letterSpacing: 2,
      color: t.secondaryText,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.charEditorInteractions.toUpperCase(), style: labelStyle),
        const SizedBox(height: 8),
        // Existing interactions
        for (final interaction in interactions) ...[
          _InteractionTile(
            interaction: interaction,
            characters: characters,
            onTap: () => _openInteractionEditor(
              context,
              sourceIndices: interaction.sourceCharacterIndices,
              targetIndices: interaction.targetCharacterIndices,
              type: interaction.type,
              existing: interaction,
            ),
          ),
          const SizedBox(height: 4),
        ],
        // Add interaction button
        InkWell(
          onTap: () => _showAddInteractionPicker(context),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: t.accent.withValues(alpha: 0.4), width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 14, color: t.accent),
                const SizedBox(width: 6),
                Text(
                  l.charEditorAddInteraction,
                  style: TextStyle(
                    fontSize: t.fontSize(8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: t.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Interaction Tile ────────────────────────────────────────────────────────

class _InteractionTile extends StatelessWidget {
  final NaiInteraction interaction;
  final List<NaiCharacter> characters;
  final VoidCallback onTap;

  const _InteractionTile({
    required this.interaction,
    required this.characters,
    required this.onTap,
  });

  String _charName(int index, BuildContext context) {
    if (index >= 0 && index < characters.length && characters[index].name.isNotEmpty) {
      return characters[index].name;
    }
    return context.l.charEditorCharacterN(index + 1);
  }

  String _joinNames(List<int> indices, BuildContext context) {
    return indices.map((i) => _charName(i, context)).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;

    final String display;
    if (interaction.type == InteractionType.mutual) {
      final participants = interaction.sourceCharacterIndices.map((i) => _charName(i, context)).join(' \u2194 ');
      display = '$participants: ${interaction.actionName}';
    } else {
      final source = _joinNames(interaction.sourceCharacterIndices, context);
      final target = _joinNames(interaction.targetCharacterIndices, context);
      display = l.charEditorInteractionDisplay(source, target, interaction.actionName);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.borderSubtle,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: t.accentSuccess.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Text(
          display,
          style: TextStyle(
            fontSize: t.fontSize(9),
            color: t.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
