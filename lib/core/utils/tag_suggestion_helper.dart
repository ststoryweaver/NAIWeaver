import 'package:flutter/material.dart';
import '../models/tag_category.dart';
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
  /// [characterSuggestionsFor] is an optional callback returning saved-character
  /// autocomplete entries that match a query (each a [DanbooruTag] with
  /// `typeName == 'saved_character'` and `expansion` set). They are slotted in
  /// just above the ordinary danbooru tag suggestions (favorited wildcards stay
  /// on top in the `__` flow; in the normal flow there are no wildcards, so
  /// characters lead).
  static TagSuggestionResult getSuggestions({
    required String text,
    required TextSelection selection,
    required TagService tagService,
    bool supportFavorites = false,
    WildcardService? wildcardService,
    List<DanbooruTag> Function(String query)? characterSuggestionsFor,
  }) {
    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      return TagSuggestionResult.empty;
    }

    final cursorPosition = selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPosition);
    final lastDelimiter = beforeCursor.lastIndexOf(RegExp(r'[,|]'));
    final currentWord = beforeCursor.substring(lastDelimiter + 1).trimLeft();

    // Strip strength prefix (e.g. "2::1gi" → lookupWord = "1gi", strength prefix = "2::")
    String lookupWord = currentWord;
    final strengthMatch = RegExp(
      r'^-?\d+(?:\.\d+)?::(.*)',
    ).firstMatch(currentWord);
    if (strengthMatch != null) lookupWord = strengthMatch.group(1)!;

    // Wildcard completion: triggered by `__`
    if (wildcardService != null && lookupWord.startsWith('__')) {
      final query = lookupWord.substring(2); // Strip leading `__`
      final suggestions = query.isEmpty
          ? wildcardService.getAll()
          : wildcardService.getSuggestions(query);
      return TagSuggestionResult(suggestions: suggestions, query: currentWord);
    }

    if (supportFavorites && lookupWord.startsWith('/f')) {
      // `/fg` general, `/fa` artist, `/fc` character, `/fr` copyright,
      // `/fm` meta, `/fs` species, `/fl` lore — see TagCategories.
      String? category;
      if (lookupWord.length > 2) {
        category = TagCategories.fromShortcutLetter(lookupWord.substring(2, 3));
      }

      return TagSuggestionResult(
        suggestions: tagService.getFavorites(category: category),
        query: currentWord,
      );
    }

    // Saved-character matches (≥2 chars). Slotted in just above the ordinary
    // danbooru tag suggestions in the normal-typing flow.
    final charMatches =
        (characterSuggestionsFor != null && lookupWord.length >= 2)
        ? characterSuggestionsFor(lookupWord)
        : const <DanbooruTag>[];

    // Category prefix detection (e.g. "artist:moj" or "artist:")
    final lowerWord = lookupWord.toLowerCase();
    for (final entry in _categoryPrefixes.entries) {
      final prefix = entry.key; // e.g. "artist:"
      final category = entry.value; // e.g. "artist"

      // Case 1: Full prefix typed (e.g. "artist:", "artist:moj")
      if (lowerWord.startsWith(prefix)) {
        final suffix = lookupWord.substring(prefix.length);
        return TagSuggestionResult(
          suggestions: tagService.getTagsByCategory(suffix, category),
          query: currentWord,
        );
      }

      // Case 2: Partial prefix typed (e.g. "ar", "art", "artist")
      if (lookupWord.length >= 2 && prefix.startsWith(lowerWord)) {
        final shortcut = DanbooruTag(
          tag: prefix,
          count: 0,
          typeName: 'category_shortcut',
        );
        final List<DanbooruTag> results = [shortcut, ...charMatches];
        // Also include normal suggestions if >= min length
        final catMinLength = TagService.containsNonAscii(lookupWord) ? 1 : 3;
        if (lookupWord.length >= catMinLength) {
          results.addAll(tagService.getSuggestions(lookupWord));
        }
        return TagSuggestionResult(suggestions: results, query: currentWord);
      }
    }

    final minLength = TagService.containsNonAscii(lookupWord) ? 1 : 3;
    if (lookupWord.length >= minLength) {
      return TagSuggestionResult(
        suggestions: [...charMatches, ...tagService.getSuggestions(lookupWord)],
        query: currentWord,
      );
    }
    if (charMatches.isNotEmpty) {
      // 2-char query that's too short for tag lookup but matched a character.
      return TagSuggestionResult(suggestions: charMatches, query: currentWord);
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
    // With no valid selection (the field was unfocused, or its text was
    // replaced programmatically before the chip tap landed) there is no
    // "current word" to replace: the trailing comma-section is a complete tag
    // the user already typed, so *append* after it instead of overwriting it.
    final appendMode = !selection.isValid || selection.baseOffset < 0;
    final String beforeCursor;
    final String afterCursor;
    final String prefix;
    final String currentSection;
    if (appendMode) {
      afterCursor = '';
      currentSection = '';
      final trimmed = text.trimRight();
      if (trimmed.isEmpty) {
        beforeCursor = prefix = '';
      } else if (trimmed.endsWith(',') || trimmed.endsWith('|')) {
        beforeCursor = prefix = '$trimmed ';
      } else {
        beforeCursor = prefix = '$trimmed, ';
      }
    } else {
      final cursorPosition = selection.baseOffset.clamp(0, text.length);
      beforeCursor = text.substring(0, cursorPosition);
      afterCursor = text.substring(cursorPosition);
      final lastDelimiter = beforeCursor.lastIndexOf(RegExp(r'[,|]'));
      prefix = beforeCursor.substring(0, lastDelimiter + 1);
      currentSection = beforeCursor.substring(lastDelimiter + 1);
    }
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

    // Saved-character expansion: insert the pre-expanded tag block (body tags +
    // outfit tags through concealment, with `nsfw` if dishevelled), not the
    // bracketed label. Falls back to the label if no expansion was attached.
    if (tag.typeName == 'saved_character') {
      final expansion =
          (tag.expansion != null && tag.expansion!.trim().isNotEmpty)
          ? tag.expansion!.trim()
          : tag.tag;
      final newBeforeCursor = "$prefix$spacer$expansion, ";
      controller.value = TextEditingValue(
        text: newBeforeCursor + afterCursor,
        selection: TextSelection.collapsed(offset: newBeforeCursor.length),
      );
      return;
    }

    // Strength-prefix preservation: if the current word starts with a
    // strength modifier (e.g. "2::"), prepend it to the inserted tag text.
    final currentWord = currentSection.trimLeft();
    final currentWordLower = currentWord.toLowerCase();
    String strengthPrefix = '';
    final strengthMatch = RegExp(
      r'^(-?\d+(?:\.\d+)?::)',
    ).firstMatch(currentWord);
    if (strengthMatch != null) {
      strengthPrefix = strengthMatch.group(1)!;
    }

    // Category-prefix preservation: if the current word (after strength prefix)
    // starts with a known prefix (e.g. "artist:"), prepend it to the inserted tag text.
    final afterStrength = currentWordLower.substring(strengthPrefix.length);
    String categoryPrefix = '';
    for (final entry in _categoryPrefixes.entries) {
      if (afterStrength.startsWith(entry.key)) {
        categoryPrefix = entry.key;
        break;
      }
    }

    final insertText = tag.matchedAlias ?? tag.tag;
    final newBeforeCursor =
        "$prefix$spacer$strengthPrefix$categoryPrefix$insertText, ";
    controller.value = TextEditingValue(
      text: newBeforeCursor + afterCursor,
      selection: TextSelection.collapsed(offset: newBeforeCursor.length),
    );
  }

  /// Appends comma-separated [negatives] to a negative-prompt [controller],
  /// skipping any tag already present (case-insensitive). Used to route a saved
  /// character's negative tags to the appropriate negative target when its
  /// autocomplete entry is picked. No-op when [negatives] is blank.
  static void appendNegatives(
    TextEditingController controller,
    String? negatives,
  ) {
    final toAdd = (negatives ?? '').trim();
    if (toAdd.isEmpty) return;

    final existing = controller.text;
    final existingKeys = existing
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet();

    final fresh = <String>[];
    for (final part in toAdd.split(',')) {
      final tag = part.trim();
      if (tag.isEmpty) continue;
      if (existingKeys.add(tag.toLowerCase())) fresh.add(tag);
    }
    if (fresh.isEmpty) return;

    final joined = fresh.join(', ');
    final needsSep =
        existing.trim().isNotEmpty && !existing.trimRight().endsWith(',');
    final newText = existing.trim().isEmpty
        ? '$joined, '
        : '${existing.trimRight()}${needsSep ? ', ' : ' '}$joined, ';
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
