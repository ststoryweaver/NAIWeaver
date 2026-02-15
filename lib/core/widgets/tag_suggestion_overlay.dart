import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../tag_service.dart';
import '../theme/theme_extensions.dart';

/// Shared tag suggestion overlay used across the main generation screen
/// and all tool editors (preset manager, style editor, etc.).
///
/// Displays color-coded tag suggestions by category with mouse-wheel scrolling.
class TagSuggestionOverlay extends StatelessWidget {
  final List<DanbooruTag> suggestions;
  final void Function(DanbooruTag tag) onTagSelected;

  /// When true, renders as a Positioned overlay (for Stack-based layouts).
  /// When false, renders inline (for Column-based layouts).
  final bool positioned;

  const TagSuggestionOverlay({
    super.key,
    required this.suggestions,
    required this.onTagSelected,
    this.positioned = false,
  });

  static Color tagColor(DanbooruTag tag) {
    switch (tag.typeName.toLowerCase()) {
      case 'copyright':
        return const Color(0xFFD880FF);
      case 'character':
        return const Color(0xFF00AD00);
      case 'artist':
        return const Color(0xFFFF5858);
      case 'meta':
        return const Color(0xFFFF9229);
      case 'wildcard':
        return const Color(0xFF00BCD4);
      case 'wildcard_favorite':
        return const Color(0xFFFFD740);
      default:
        return Colors.white;
    }
  }

  Widget _buildContent(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    final t = context.t;

    return AnimatedOpacity(
      opacity: suggestions.isNotEmpty ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: suggestions.isEmpty,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: positioned
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
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                final newOffset = scrollController.offset + pointerSignal.scrollDelta.dy;
                scrollController.jumpTo(
                  newOffset.clamp(0.0, scrollController.position.maxScrollExtent),
                );
              }
            },
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: suggestions.map((tag) {
                  final color = tagColor(tag);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => onTagSelected(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Text(
                              tag.tag,
                              style: TextStyle(
                                color: color,
                                fontSize: t.fontSize(10),
                                fontWeight: FontWeight.bold,
                                shadows: const [Shadow(color: Colors.black54, blurRadius: 1)],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              NumberFormat.compact().format(tag.count),
                              style: TextStyle(
                                color: color.withValues(alpha: 0.4),
                                fontSize: t.fontSize(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (positioned) {
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
