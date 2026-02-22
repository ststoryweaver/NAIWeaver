import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/tag_suggestion_overlay.dart';
import '../../../core/services/tag_service.dart';
import '../providers/generation_notifier.dart';
import '../models/nai_character.dart';
import 'nai_grid_selector.dart';

class CharacterEditorSheet extends StatefulWidget {
  final int index;
  final NaiCharacter character;
  final Function(NaiCharacter) onSave;
  final VoidCallback onDelete;

  const CharacterEditorSheet({
    super.key,
    required this.index,
    required this.character,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<CharacterEditorSheet> createState() => _CharacterEditorSheetState();
}

class _CharacterEditorSheetState extends State<CharacterEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _promptController;
  late TextEditingController _ucController;
  late FocusNode _promptFocusNode;
  late FocusNode _ucFocusNode;
  late NaiCoordinate _coordinate;

  List<DanbooruTag> _promptSuggestions = [];
  List<DanbooruTag> _ucSuggestions = [];
  bool _saved = false;
  bool _deleted = false;
  TagService? _tagService;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character.name);
    _promptController = TextEditingController(text: widget.character.prompt);
    _ucController = TextEditingController(text: widget.character.uc);
    _promptFocusNode = FocusNode();
    _ucFocusNode = FocusNode();
    _coordinate = widget.character.center;
    _promptController.addListener(_updatePromptSuggestions);
    _ucController.addListener(_updateUcSuggestions);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tagService ??= context.read<GenerationNotifier>().tagService;
  }

  void _updatePromptSuggestions() {
    if (!mounted) return;
    final text = _promptController.text;
    if (_tagService == null || text.isEmpty) {
      if (_promptSuggestions.isNotEmpty) setState(() => _promptSuggestions = []);
      return;
    }
    final parts = text.split(',');
    final lastPart = parts.last.trim();
    final minLength = TagService.containsNonAscii(lastPart) ? 1 : 2;
    if (lastPart.length < minLength) {
      if (_promptSuggestions.isNotEmpty) setState(() => _promptSuggestions = []);
      return;
    }
    final suggestions = _tagService!.getSuggestions(lastPart);
    setState(() => _promptSuggestions = suggestions);
  }

  void _updateUcSuggestions() {
    if (!mounted) return;
    final text = _ucController.text;
    if (_tagService == null || text.isEmpty) {
      if (_ucSuggestions.isNotEmpty) setState(() => _ucSuggestions = []);
      return;
    }
    final parts = text.split(',');
    final lastPart = parts.last.trim();
    final minLength = TagService.containsNonAscii(lastPart) ? 1 : 2;
    if (lastPart.length < minLength) {
      if (_ucSuggestions.isNotEmpty) setState(() => _ucSuggestions = []);
      return;
    }
    final suggestions = _tagService!.getSuggestions(lastPart);
    setState(() => _ucSuggestions = suggestions);
  }

  void _onTagSelected(TextEditingController controller, DanbooruTag tag) {
    final insertText = tag.matchedAlias ?? tag.tag;
    final currentText = controller.text;
    final parts = currentText.split(',');
    parts.removeLast();
    final newText = parts.isEmpty
        ? '$insertText, '
        : '${parts.join(',')}, $insertText, ';
    controller.text = newText;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );
  }

  void _saveChanges() {
    if (_saved || _deleted) return;
    _saved = true;
    widget.onSave(NaiCharacter(
      name: _nameController.text,
      prompt: _promptController.text,
      uc: _ucController.text,
      center: _coordinate,
    ));
  }

  void _save() {
    _saveChanges();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _saveChanges();
    _promptController.removeListener(_updatePromptSuggestions);
    _ucController.removeListener(_updateUcSuggestions);
    _nameController.dispose();
    _promptController.dispose();
    _ucController.dispose();
    _promptFocusNode.dispose();
    _ucFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final genNotifier = context.read<GenerationNotifier>();
    final autoPositioning = genNotifier.state.autoPositioning;

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
                'CHARACTER ${widget.index + 1} EDITOR',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: t.fontSize(12),
                  letterSpacing: 4,
                  color: t.textPrimary,
                ),
              ),
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
            'CHARACTER NAME',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: t.fontSize(9),
              letterSpacing: 2,
              color: t.textDisabled,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            style: TextStyle(fontSize: t.fontSize(13), color: t.textSecondary, height: 1.4),
            decoration: InputDecoration(
              hintText: 'NAME (OPTIONAL)',
              hintStyle: TextStyle(fontSize: t.fontSize(9), color: t.textMinimal, letterSpacing: 2),
              fillColor: t.borderSubtle,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.textMinimal)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'CHARACTER PROMPT',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: t.fontSize(9),
              letterSpacing: 2,
              color: t.textDisabled,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _promptController,
            focusNode: _promptFocusNode,
            style: TextStyle(fontSize: t.fontSize(13), color: t.textSecondary, height: 1.4),
            decoration: InputDecoration(
              hintText: 'ENTER TAGS',
              hintStyle: TextStyle(fontSize: t.fontSize(9), color: t.textMinimal, letterSpacing: 2),
              fillColor: t.borderSubtle,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.textMinimal)),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
            minLines: 1,
          ),
          TagSuggestionOverlay(
            suggestions: _promptSuggestions,
            onTagSelected: (tag) => _onTagSelected(_promptController, tag),
          ),
          const SizedBox(height: 20),
          Text(
            'CHARACTER UC',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: t.fontSize(9),
              letterSpacing: 2,
              color: t.textDisabled,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ucController,
            focusNode: _ucFocusNode,
            style: TextStyle(fontSize: t.fontSize(13), color: t.textSecondary, height: 1.4),
            decoration: InputDecoration(
              hintText: 'ENTER TAGS',
              hintStyle: TextStyle(fontSize: t.fontSize(9), color: t.textMinimal, letterSpacing: 2),
              fillColor: t.borderSubtle,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: t.textMinimal)),
              contentPadding: const EdgeInsets.all(16),
            ),
            maxLines: 3,
            minLines: 1,
          ),
          TagSuggestionOverlay(
            suggestions: _ucSuggestions,
            onTagSelected: (tag) => _onTagSelected(_ucController, tag),
          ),
          const SizedBox(height: 24),
          if (autoPositioning)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                'AI DECIDES POSITION',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: t.fontSize(10),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            )
          else ...[
            Text(
              'POSITION (5x5 GRID)',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: t.fontSize(9),
                letterSpacing: 2,
                color: t.textDisabled,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: t.borderSubtle),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(8),
                child: NaiGridSelector(
                  selectedCoordinate: _coordinate,
                  onCoordinateSelected: (coord) {
                    setState(() => _coordinate = coord);
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: t.accent,
              foregroundColor: t.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(
              'SAVE CHARACTER',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: t.fontSize(10)),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
