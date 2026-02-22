import 'package:flutter/material.dart';
import '../services/tag_service.dart';
import '../services/wildcard_service.dart';

class TagSuggestionResult {
  final List<DanbooruTag> suggestions;
  final String query;

  const TagSuggestionResult({required this.suggestions, required this.query});

  static const empty = TagSuggestionResult(suggestions: [], query: "");
}

/// Shared logic for tag auto-suggestion across prompt text fields.
class TagSuggestionHelper {
  static const _categoryPrefixes = {'artist:': 'artist'};

  /// Extracts the current word at the cursor and returns matching tag suggestions.
  ///
  /// When [supportFavorites] is true, `/f` shortcuts are recognized
  /// (e.g. `/fg` for general favorites, `/fa` for artist, etc.).
  ///
  /// When [wildcardService] is provided, typing `__` triggers wildcard
  /// auto-completion (e.g. `__hair` suggests `__hairstyles__`).
  static TagSuggestionResult getSuggestions({
    required String text,
    required TextSelection selection,
    required TagService tagService,
    bool supportFavorites = false,
    WildcardService? wildcardService,
  }) {
    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      return TagSuggestionResult.empty;
    }

    final cursorPosition = selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPosition);
    final lastDelimiter = beforeCursor.lastIndexOf(RegExp(r'[,|]'));
    final currentWord = beforeCursor.substring(lastDelimiter + 1).trimLeft();

    // Wildcard completion: triggered by `__`
    if (wildcardService != null && currentWord.startsWith('__')) {
      final query = currentWord.substring(2); // Strip leading `__`
      final suggestions = query.isEmpty
          ? wildcardService.getAll()
          : wildcardService.getSuggestions(query);
      return TagSuggestionResult(
        suggestions: suggestions,
        query: currentWord,
      );
    }

    if (supportFavorites && currentWord.startsWith('/f')) {
      String? category;
      if (currentWord.length > 2) {
        switch (currentWord.substring(2, 3)) {
          case 'g': category = 'general'; break;
          case 'a': category = 'artist'; break;
          case 'c': category = 'character'; break;
          case 'r': category = 'copyright'; break;
          case 'm': category = 'meta'; break;
        }
      }

      return TagSuggestionResult(
        suggestions: tagService.getFavorites(category: category),
        query: currentWord,
      );
    }

    // Category prefix detection (e.g. "artist:moj" or "artist:")
    final lowerWord = currentWord.toLowerCase();
    for (final entry in _categoryPrefixes.entries) {
      final prefix = entry.key;   // e.g. "artist:"
      final category = entry.value; // e.g. "artist"

      // Case 1: Full prefix typed (e.g. "artist:", "artist:moj")
      if (lowerWord.startsWith(prefix)) {
        final suffix = currentWord.substring(prefix.length);
        return TagSuggestionResult(
          suggestions: tagService.getTagsByCategory(suffix, category),
          query: currentWord,
        );
      }

      // Case 2: Partial prefix typed (e.g. "ar", "art", "artist")
      if (currentWord.length >= 2 && prefix.startsWith(lowerWord)) {
        final shortcut = DanbooruTag(
          tag: prefix,
          count: 0,
          typeName: 'category_shortcut',
        );
        final List<DanbooruTag> results = [shortcut];
        // Also include normal suggestions if >= min length
        final catMinLength = TagService.containsNonAscii(currentWord) ? 1 : 3;
        if (currentWord.length >= catMinLength) {
          results.addAll(tagService.getSuggestions(currentWord));
        }
        return TagSuggestionResult(
          suggestions: results,
          query: currentWord,
        );
      }
    }

    final minLength = TagService.containsNonAscii(currentWord) ? 1 : 3;
    if (currentWord.length >= minLength) {
      return TagSuggestionResult(
        suggestions: tagService.getSuggestions(currentWord),
        query: currentWord,
      );
    }

    return TagSuggestionResult.empty;
  }

  /// Replaces the current word at the cursor with the selected tag.
  ///
  /// For wildcard tags (typeName starts with 'wildcard'), the tag is inserted
  /// as-is (already in `__name__` format) followed by a comma and space.
  static void applyTag(TextEditingController controller, DanbooruTag tag) {
    final text = controller.text;
    final selection = controller.selection;
    final cursorPosition = selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);

    final lastDelimiter = beforeCursor.lastIndexOf(RegExp(r'[,|]'));
    final prefix = beforeCursor.substring(0, lastDelimiter + 1);
    final currentSection = beforeCursor.substring(lastDelimiter + 1);
    final spacer = currentSection.startsWith(' ') ? ' ' : '';

    // Shortcut insertion (e.g. "artist:") — insert without trailing comma
    if (tag.typeName == 'category_shortcut') {
      final newBeforeCursor = "$prefix$spacer${tag.tag}";
      controller.value = TextEditingValue(
        text: newBeforeCursor + afterCursor,
        selection: TextSelection.collapsed(offset: newBeforeCursor.length),
      );
      return;
    }

    // Category-prefix preservation: if the current word starts with a known
    // prefix (e.g. "artist:"), prepend it to the inserted tag text.
    final currentWord = currentSection.trimLeft().toLowerCase();
    String categoryPrefix = '';
    for (final entry in _categoryPrefixes.entries) {
      if (currentWord.startsWith(entry.key)) {
        categoryPrefix = entry.key;
        break;
      }
    }

    final insertText = tag.matchedAlias ?? tag.tag;
    final newBeforeCursor = "$prefix$spacer$categoryPrefix$insertText, ";
    controller.value = TextEditingValue(
      text: newBeforeCursor + afterCursor,
      selection: TextSelection.collapsed(offset: newBeforeCursor.length),
    );
  }
}
