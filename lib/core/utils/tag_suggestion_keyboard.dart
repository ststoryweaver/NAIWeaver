import '../services/tag_service.dart';

/// Keyboard bindings for an inline tag-suggestion overlay.
///
/// Matches the main prompt: Tab / Shift+Tab cycle the highlight, Enter
/// inserts the highlighted chip. With no suggestions, Tab is left for
/// focus traversal.
class TagSuggestionKeyboard {
  int selectedIndex = -1;

  void reset() => selectedIndex = -1;

  /// Advances [selectedIndex]. Returns `false` when there is nothing to
  /// cycle so the caller can let Tab move focus.
  bool cycle({required int suggestionCount, required bool reverse}) {
    if (suggestionCount <= 0) return false;
    if (reverse) {
      selectedIndex = (selectedIndex - 1).clamp(-1, suggestionCount - 1);
    } else {
      selectedIndex = (selectedIndex + 1) % suggestionCount;
    }
    return true;
  }

  /// The highlighted suggestion, or `null` if nothing is selected.
  /// Clears the highlight so the next Tab starts fresh.
  DanbooruTag? accept(List<DanbooruTag> suggestions) {
    if (selectedIndex < 0 || selectedIndex >= suggestions.length) {
      return null;
    }
    final tag = suggestions[selectedIndex];
    selectedIndex = -1;
    return tag;
  }
}
