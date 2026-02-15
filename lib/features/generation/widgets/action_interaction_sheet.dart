import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/tag_suggestion_overlay.dart';
import '../../../tag_service.dart';
import '../models/nai_character.dart';
import '../providers/generation_notifier.dart';

class ActionInteractionSheet extends StatefulWidget {
  final int index1;
  final int index2;
  final NaiInteraction? initialInteraction;
  final Function(NaiInteraction) onSave;
  final VoidCallback onDelete;

  const ActionInteractionSheet({
    super.key,
    required this.index1,
    required this.index2,
    this.initialInteraction,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<ActionInteractionSheet> createState() => _ActionInteractionSheetState();
}

class _ActionInteractionSheetState extends State<ActionInteractionSheet> {
  late TextEditingController _actionController;
  late FocusNode _actionFocusNode;
  late InteractionType _type;
  late int _sourceIndex;
  late int _targetIndex;

  List<DanbooruTag> _actionSuggestions = [];
  bool _saved = false;
  bool _deleted = false;
  TagService? _tagService;

  @override
  void initState() {
    super.initState();
    _actionController = TextEditingController(text: widget.initialInteraction?.actionName ?? "");
    _actionFocusNode = FocusNode();
    _type = widget.initialInteraction?.type ?? InteractionType.sourceTarget;
    _sourceIndex = widget.initialInteraction?.sourceCharacterIndex ?? widget.index1;
    _targetIndex = widget.initialInteraction?.targetCharacterIndex ?? widget.index2;
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
      if (_actionSuggestions.isNotEmpty) setState(() => _actionSuggestions = []);
      return;
    }
    String query = text;
    if (query.startsWith('/f ')) query = query.substring(3);
    if (query.length < 2) {
      if (_actionSuggestions.isNotEmpty) setState(() => _actionSuggestions = []);
      return;
    }
    final suggestions = _tagService?.getSuggestions(query)
        .where((tag) => tag.typeName.toLowerCase() == 'general')
        .toList() ?? [];
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
    // Clear suggestions after selection
    setState(() => _actionSuggestions = []);
  }

  void _saveChanges() {
    if (_saved || _deleted) return;
    if (_actionController.text.trim().isEmpty) return;
    _saved = true;
    widget.onSave(NaiInteraction(
      sourceCharacterIndex: _sourceIndex,
      targetCharacterIndex: _targetIndex,
      actionName: _actionController.text.trim(),
      type: _type,
    ));
  }

  void _toggleDirection() {
    setState(() {
      if (_type == InteractionType.mutual) {
        _type = InteractionType.sourceTarget;
        _sourceIndex = widget.index1;
        _targetIndex = widget.index2;
      } else if (_sourceIndex == widget.index1) {
        _sourceIndex = widget.index2;
        _targetIndex = widget.index1;
      } else {
        _type = InteractionType.mutual;
      }
    });
  }

  String _getDirectionLabel() {
    if (_type == InteractionType.mutual) return "C${_sourceIndex + 1} <-> C${_targetIndex + 1}";
    if (_sourceIndex == widget.index1) return "C${widget.index1 + 1} -> C${widget.index2 + 1}";
    return "C${widget.index1 + 1} <- C${widget.index2 + 1}";
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
                'INTERACTION EDITOR',
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
                  icon: Icon(Icons.delete_outline, color: t.accentDanger, size: 18),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'ACTION',
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
            style: TextStyle(fontSize: t.fontSize(13), color: t.textSecondary, height: 1.4),
            decoration: InputDecoration(
              hintText: 'ENTER ACTION (e.g., hugging)',
              hintStyle: TextStyle(fontSize: t.fontSize(9), color: t.textMinimal, letterSpacing: 2),
              fillColor: t.borderSubtle,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.textMinimal)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          TagSuggestionOverlay(
            suggestions: _actionSuggestions,
            onTagSelected: _onActionTagSelected,
          ),
          const SizedBox(height: 20),
          Text(
            'DIRECTION',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: t.fontSize(9),
              letterSpacing: 2,
              color: t.textDisabled,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _toggleDirection,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: t.borderMedium),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.centerLeft,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _getDirectionLabel(),
                style: TextStyle(color: t.textPrimary, fontSize: t.fontSize(11), fontWeight: FontWeight.bold),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(
              'SAVE INTERACTION',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: t.fontSize(10)),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
