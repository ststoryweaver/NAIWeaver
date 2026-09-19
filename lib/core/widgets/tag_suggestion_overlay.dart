import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/tag_category.dart';
import '../services/preferences_service.dart';
import '../services/tag_service.dart';
import '../utils/tag_suggestion_helper.dart';
import '../theme/theme_extensions.dart';

/// Shared tag suggestion overlay used across the main generation screen
/// and all tool editors (preset manager, style editor, etc.).
///
/// Displays color-coded tag suggestions by category with mouse-wheel scrolling.
/// When any of the suggestions is a saved-character entry, an inline "honor
/// state" toggle is shown — when off (default) the flat tag string is
/// inserted; when on the state-aware expansion (with concealment + optional
/// `nsfw` append) is inserted. The choice is persisted across sessions via
/// [PreferencesService.honorOutfitState] as a UX convenience.
class TagSuggestionOverlay extends StatefulWidget {
  final List<DanbooruTag> suggestions;
  final void Function(DanbooruTag tag) onTagSelected;

  /// When true, renders as a Positioned overlay (for Stack-based layouts).
  /// When false, renders inline (for Column-based layouts).
  final bool positioned;

  /// Index of the keyboard-selected suggestion (-1 = none).
  final int selectedIndex;

  const TagSuggestionOverlay({
    super.key,
    required this.suggestions,
    required this.onTagSelected,
    this.positioned = false,
    this.selectedIndex = -1,
  });

  static Color tagColor(DanbooruTag tag) =>
      TagCategories.colorFor(tag.typeName);

  @override
  State<TagSuggestionOverlay> createState() => _TagSuggestionOverlayState();
}

class _TagSuggestionOverlayState extends State<TagSuggestionOverlay> {
  void _selectTag(DanbooruTag tag) {
    widget.onTagSelected(
      TagSuggestionHelper.resolveSelection(
        tag,
        honorOutfitState: context.read<PreferencesService>().honorOutfitState,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    final t = context.t;
    final hasCharacterSuggestions = widget.suggestions.any(
      (s) => s.typeName == 'saved_character' && s.flatExpansion != null,
    );

    return AnimatedOpacity(
      opacity: widget.suggestions.isNotEmpty ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: widget.suggestions.isEmpty,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: widget.positioned
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      t.background,
                      t.background.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                )
              : BoxDecoration(
                  color: t.background.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: t.borderMedium),
                ),
          // The whole panel (chips *and* the outfit-state toggle) is part of
          // the originating TextField's tap group: on desktop a TextField
          // unfocuses itself on pointer-down outside its TapRegion, which
          // would tear this overlay down before a tap could land. Inside the
          // group, a tap here counts as "inside" the field and focus is kept.
          child: TextFieldTapRegion(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasCharacterSuggestions) _honorToggle(context, t),
                  Flexible(
                    child: Listener(
                      onPointerSignal: (pointerSignal) {
                        if (pointerSignal is PointerScrollEvent) {
                          final newOffset =
                              scrollController.offset +
                              pointerSignal.scrollDelta.dy;
                          scrollController.jumpTo(
                            newOffset.clamp(
                              0.0,
                              scrollController.position.maxScrollExtent,
                            ),
                          );
                        }
                      },
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: List.generate(widget.suggestions.length, (
                            index,
                          ) {
                            final tag = widget.suggestions[index];
                            final color = TagSuggestionOverlay.tagColor(tag);
                            final isHighlighted = index == widget.selectedIndex;
                            return InkWell(
                              onTap: () => _selectTag(tag),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? color.withValues(alpha: 0.35)
                                      : color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: isHighlighted
                                        ? color.withValues(alpha: 0.8)
                                        : color.withValues(alpha: 0.4),
                                    width: isHighlighted ? 1.5 : 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (tag.matchedAlias != null) ...[
                                      Text(
                                        tag.matchedAlias!,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: t.fontSize(10),
                                          fontWeight: FontWeight.bold,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        ' → ',
                                        style: TextStyle(
                                          color: color.withValues(alpha: 0.5),
                                          fontSize: t.fontSize(9),
                                        ),
                                      ),
                                      Text(
                                        tag.tag,
                                        style: TextStyle(
                                          color: color.withValues(alpha: 0.6),
                                          fontSize: t.fontSize(9),
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        tag.tag,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: t.fontSize(10),
                                          fontWeight: FontWeight.bold,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (tag.sourceId != null) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        context.read<TagService>().sourceBadge(
                                              tag.sourceId,
                                            ) ??
                                            '',
                                        style: TextStyle(
                                          color: color.withValues(alpha: 0.55),
                                          fontSize: t.fontSize(7),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                    if (!context
                                            .read<PreferencesService>()
                                            .hideTagValues &&
                                        tag.typeName != 'category_shortcut' &&
                                        tag.typeName != 'saved_character') ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        NumberFormat.compact().format(
                                          tag.count,
                                        ),
                                        style: TextStyle(
                                          color: color.withValues(alpha: 0.4),
                                          fontSize: t.fontSize(8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _honorToggle(BuildContext context, t) {
    final prefs = context.read<PreferencesService>();
    final honor = prefs.honorOutfitState;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
      child: InkWell(
        onTap: () async {
          await prefs.setHonorOutfitState(!honor);
          if (mounted) setState(() {});
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: t.surfaceMid,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: honor ? t.borderStrong : t.borderSubtle,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                honor
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
                size: 13,
                color: honor ? t.textSecondary : t.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                'honor outfit state',
                style: TextStyle(
                  color: honor ? t.textSecondary : t.textTertiary,
                  fontSize: t.fontSize(9),
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.positioned) {
      return Positioned(
        top: 9,
        left: 0,
        right: 0,
        child: _buildContent(context),
      );
    }
    return _buildContent(context);
  }
}
