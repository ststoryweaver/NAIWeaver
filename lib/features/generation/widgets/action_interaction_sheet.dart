import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/theme/vision_tokens.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/widgets/tag_suggestion_overlay.dart';
import '../../../core/services/tag_service.dart';
import '../models/nai_character.dart';
import '../providers/generation_notifier.dart';

class ActionInteractionSheet extends StatefulWidget {
  final List<int> sourceIndices;
  final List<int> targetIndices;
  final InteractionType initialType;
  final List<NaiCharacter> characters;
  final NaiInteraction? initialInteraction;
  final Function(NaiInteraction) onSave;
  final VoidCallback onDelete;

  /// When set, the sheet treats this character as the one whose link button
  /// was pressed and shows a partner picker plus forward/reverse/mutual
  /// direction controls. When null, the original two-party cycle is used.
  final int? anchorIndex;

  const ActionInteractionSheet({
    super.key,
    required this.sourceIndices,
    required this.targetIndices,
    required this.initialType,
    required this.characters,
    this.initialInteraction,
    required this.onSave,
    required this.onDelete,
    this.anchorIndex,
  });

  @override
  State<ActionInteractionSheet> createState() => _ActionInteractionSheetState();
}

class _ActionInteractionSheetState extends State<ActionInteractionSheet> {
  late TextEditingController _actionController;
  late FocusNode _actionFocusNode;
  late InteractionType _type;
  late List<int> _sourceIndices;
  late List<int> _targetIndices;
  int? _partnerIndex;

  /// 0 = anchor → partner, 1 = mutual, 2 = anchor ← partner (reverse).
  int _dirMode = 0;

  List<DanbooruTag> _actionSuggestions = [];
  bool _saved = false;
  bool _deleted = false;
  TagService? _tagService;

  @override
  void initState() {
    super.initState();
    _actionController = TextEditingController(
      text: widget.initialInteraction?.actionName ?? "",
    );
    _actionFocusNode = FocusNode();
    _type = widget.initialInteraction?.type ?? widget.initialType;
    _sourceIndices =
        widget.initialInteraction?.sourceCharacterIndices.toList() ??
        widget.sourceIndices.toList();
    _targetIndices =
        widget.initialInteraction?.targetCharacterIndices.toList() ??
        widget.targetIndices.toList();
    final anchor = widget.anchorIndex;
    if (anchor != null) {
      final others = [
        for (int i = 0; i < widget.characters.length; i++)
          if (i != anchor) i,
      ];
      int? pickPartner(Iterable<int> from) {
        for (final i in from) {
          if (i != anchor) return i;
        }
        return others.isEmpty ? null : others.first;
      }

      final existing = widget.initialInteraction;
      if (existing != null) {
        if (existing.type == InteractionType.mutual) {
          _dirMode = 1;
          _partnerIndex = pickPartner(existing.sourceCharacterIndices);
        } else if (existing.sourceCharacterIndices.contains(anchor)) {
          _dirMode = 0;
          _partnerIndex = pickPartner(existing.targetCharacterIndices);
        } else {
          _dirMode = 2;
          _partnerIndex = pickPartner(existing.sourceCharacterIndices);
        }
      } else {
        _partnerIndex = pickPartner(widget.targetIndices);
        _dirMode = widget.initialType == InteractionType.mutual ? 1 : 0;
      }
      _applyDirMode();
    }
    _actionController.addListener(_updateActionSuggestions);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tagService ??= context.read<GenerationNotifier>().tagService;
  }

  void _updateActionSuggestions() {
    if (!mounted) return;
    final text = _actionController.text;
    if (text.isEmpty) {
      if (_actionSuggestions.isNotEmpty) {
        setState(() => _actionSuggestions = []);
      }
      return;
    }
    String query = text;
    if (query.startsWith('/f ')) query = query.substring(3);
    if (query.length < 2) {
      if (_actionSuggestions.isNotEmpty) {
        setState(() => _actionSuggestions = []);
      }
      return;
    }
    final suggestions =
        _tagService
            ?.getSuggestions(query)
            .where((tag) => tag.typeName.toLowerCase() == 'general')
            .toList() ??
        [];
    setState(() => _actionSuggestions = suggestions);
  }

  void _onActionTagSelected(DanbooruTag tag) {
    if (_actionController.text.startsWith('/f ')) {
      _actionController.text = '/f ${tag.tag}';
    } else {
      _actionController.text = tag.tag;
    }
    _actionController.selection = TextSelection.fromPosition(
      TextPosition(offset: _actionController.text.length),
    );
    setState(() => _actionSuggestions = []);
  }

  void _saveChanges() {
    if (_saved || _deleted) return;
    if (_actionController.text.trim().isEmpty) return;
    _saved = true;
    widget.onSave(
      NaiInteraction(
        sourceCharacterIndices: _sourceIndices,
        targetCharacterIndices: _targetIndices,
        actionName: _actionController.text.trim(),
        type: _type,
      ),
    );
  }

  void _applyDirMode() {
    final anchor = widget.anchorIndex;
    final partner = _partnerIndex;
    if (anchor == null || partner == null) return;
    if (_dirMode == 1) {
      _type = InteractionType.mutual;
      _sourceIndices = [anchor, partner];
      _targetIndices = [];
    } else if (_dirMode == 2) {
      _type = InteractionType.sourceTarget;
      _sourceIndices = [partner];
      _targetIndices = [anchor];
    } else {
      _type = InteractionType.sourceTarget;
      _sourceIndices = [anchor];
      _targetIndices = [partner];
    }
  }

  void _cycleDirMode() {
    setState(() {
      _dirMode = (_dirMode + 1) % 3;
      _applyDirMode();
    });
  }

  String _anchorDirectionLabel() {
    final left = _charName(widget.anchorIndex!);
    final right = _partnerIndex != null ? _charName(_partnerIndex!) : '?';
    const arrows = ['\u2192', '\u2194', '\u2190']; // →  ↔  ←
    return '$left ${arrows[_dirMode]} $right';
  }

  void _toggleDirection() {
    setState(() {
      if (_type == InteractionType.sourceTarget) {
        // Swap source and target
        final tmp = _sourceIndices;
        _sourceIndices = _targetIndices;
        _targetIndices = tmp;
        // If we've swapped back to original, go to mutual
        if (_listEquals(_sourceIndices, widget.targetIndices)) {
          _type = InteractionType.mutual;
          _sourceIndices = [...widget.sourceIndices, ...widget.targetIndices];
          _targetIndices = [];
        }
      } else {
        // From mutual back to sourceTarget with original assignment
        _type = InteractionType.sourceTarget;
        _sourceIndices = widget.sourceIndices.toList();
        _targetIndices = widget.targetIndices.toList();
      }
    });
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _charName(int index) {
    if (index >= 0 &&
        index < widget.characters.length &&
        widget.characters[index].name.isNotEmpty) {
      return widget.characters[index].name;
    }
    return 'C${index + 1}';
  }

  String _getDirectionLabel() {
    if (_type == InteractionType.mutual) {
      return _sourceIndices.map(_charName).join(' \u2194 ');
    }
    final src = _sourceIndices.map(_charName).join(', ');
    final tgt = _targetIndices.map(_charName).join(', ');
    return '$src \u2192 $tgt';
  }

  Widget _buildAnchorDirection(VisionTokens t) {
    final anchor = widget.anchorIndex!;
    final partners = [
      for (int i = 0; i < widget.characters.length; i++)
        if (i != anchor) i,
    ];
    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? t.accent.withValues(alpha: 0.2) : t.surfaceHigh,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: selected ? t.accent : t.borderMedium),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? t.accent : t.textPrimary,
              fontSize: t.fontSize(10),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l.interactionWithLabel,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: t.fontSize(8),
            letterSpacing: 2,
            color: t.textDisabled,
          ),
        ),
        const SizedBox(height: 8),
        if (partners.isEmpty)
          Text(
            context.l.interactionNeedPartner,
            style: TextStyle(color: t.textDisabled, fontSize: t.fontSize(10)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in partners)
                chip(
                  label: _charName(i),
                  selected: _partnerIndex == i,
                  onTap: () => setState(() {
                    _partnerIndex = i;
                    _applyDirMode();
                  }),
                ),
            ],
          ),
        if (partners.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _cycleDirMode,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: t.borderMedium),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                _anchorDirectionLabel(),
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: t.fontSize(11),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _saveChanges();
    _actionController.removeListener(_updateActionSuggestions);
    _actionController.dispose();
    _actionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Container(
      color: t.surfaceMid,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l.interactionEditorTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: t.fontSize(12),
                    letterSpacing: 4,
                    color: t.textPrimary,
                  ),
                ),
                if (widget.initialInteraction != null)
                  IconButton(
                    onPressed: () {
                      _deleted = true;
                      widget.onDelete();
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: t.accentDanger,
                      size: 18,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              context.l.interactionActionLabel,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: t.fontSize(9),
                letterSpacing: 2,
                color: t.textDisabled,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _actionController,
              focusNode: _actionFocusNode,
              autofocus: true,
              style: TextStyle(
                fontSize: t.fontSize(13),
                color: t.textSecondary,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: context.l.interactionActionHint,
                hintStyle: TextStyle(
                  fontSize: t.fontSize(9),
                  color: t.textMinimal,
                  letterSpacing: 2,
                ),
                fillColor: t.surfaceHigh,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: t.textMinimal),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            TagSuggestionOverlay(
              suggestions: _actionSuggestions,
              onTagSelected: _onActionTagSelected,
            ),
            const SizedBox(height: 20),
            Text(
              context.l.interactionDirectionLabel,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: t.fontSize(9),
                letterSpacing: 2,
                color: t.textDisabled,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.anchorIndex != null)
              _buildAnchorDirection(t)
            else
              OutlinedButton(
                onPressed: _toggleDirection,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: t.borderMedium),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _getDirectionLabel(),
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: t.fontSize(11),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _saveChanges();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: t.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                context.l.interactionSave,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: t.fontSize(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
