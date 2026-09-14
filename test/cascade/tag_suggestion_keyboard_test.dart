import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/services/tag_service.dart';
import 'package:naiweaver/core/utils/tag_suggestion_helper.dart';
import 'package:naiweaver/core/utils/tag_suggestion_keyboard.dart';

DanbooruTag _t(String name) => DanbooruTag(tag: name, count: 1);

DanbooruTag _char(String name, String expansion) => DanbooruTag(
      tag: name,
      count: 0,
      typeName: 'saved_character',
      expansion: expansion,
    );

void main() {
  group('TagSuggestionKeyboard.cycle', () {
    test('Tab with no suggestions is ignored so focus can move', () {
      final keys = TagSuggestionKeyboard();
      expect(keys.cycle(suggestionCount: 0, reverse: false), isFalse);
      expect(keys.selectedIndex, -1);
    });

    test('Tab walks 0, 1, 2, then wraps to 0', () {
      final keys = TagSuggestionKeyboard();
      expect(keys.cycle(suggestionCount: 3, reverse: false), isTrue);
      expect(keys.selectedIndex, 0);
      expect(keys.cycle(suggestionCount: 3, reverse: false), isTrue);
      expect(keys.selectedIndex, 1);
      expect(keys.cycle(suggestionCount: 3, reverse: false), isTrue);
      expect(keys.selectedIndex, 2);
      expect(keys.cycle(suggestionCount: 3, reverse: false), isTrue);
      expect(keys.selectedIndex, 0);
    });

    test('Shift+Tab steps back and stops at none highlighted', () {
      final keys = TagSuggestionKeyboard();
      keys.cycle(suggestionCount: 3, reverse: false);
      keys.cycle(suggestionCount: 3, reverse: false);
      expect(keys.selectedIndex, 1);

      expect(keys.cycle(suggestionCount: 3, reverse: true), isTrue);
      expect(keys.selectedIndex, 0);
      expect(keys.cycle(suggestionCount: 3, reverse: true), isTrue);
      expect(keys.selectedIndex, -1);
      expect(keys.cycle(suggestionCount: 3, reverse: true), isTrue);
      expect(keys.selectedIndex, -1);
    });
  });

  group('TagSuggestionKeyboard.accept', () {
    final suggestions = [_t('1girl'), _t('1boy'), _char('male bro', '1boy, short hair')];

    test('Enter with nothing highlighted does not insert', () {
      final keys = TagSuggestionKeyboard();
      expect(keys.accept(suggestions), isNull);
    });

    test('Enter inserts the highlighted chip and clears the highlight', () {
      final keys = TagSuggestionKeyboard();
      keys.cycle(suggestionCount: suggestions.length, reverse: false);
      keys.cycle(suggestionCount: suggestions.length, reverse: false);
      expect(keys.selectedIndex, 1);

      final inserted = keys.accept(suggestions);
      expect(inserted?.tag, '1boy');
      expect(keys.selectedIndex, -1);
    });

    test('Tab to a saved character then accept yields that character', () {
      final keys = TagSuggestionKeyboard();
      keys.cycle(suggestionCount: suggestions.length, reverse: false); // 1girl
      keys.cycle(suggestionCount: suggestions.length, reverse: false); // 1boy
      keys.cycle(suggestionCount: suggestions.length, reverse: false); // male bro
      final inserted = keys.accept(suggestions);
      expect(inserted?.typeName, 'saved_character');
      expect(inserted?.tag, 'male bro');
      expect(inserted?.expansion, '1boy, short hair');
    });
  });

  group('cascade editor insert after Tab (applyTag)', () {
    test('replaces the typed query with a normal tag', () {
      final c = TextEditingController(text: '1gi');
      c.selection = const TextSelection.collapsed(offset: 3);
      TagSuggestionHelper.applyTag(c, _t('1girl'));
      expect(c.text, '1girl, ');
    });

    test('replaces the typed query with a saved-character expansion', () {
      final c = TextEditingController(text: 'male');
      c.selection = const TextSelection.collapsed(offset: 4);
      TagSuggestionHelper.applyTag(c, _char('male bro', '1boy, short hair'));
      expect(c.text, '1boy, short hair, ');
      expect(c.text.startsWith('male '), isFalse);
    });
  });
}
