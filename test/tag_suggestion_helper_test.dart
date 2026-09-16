import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/services/tag_service.dart';
import 'package:naiweaver/core/utils/tag_suggestion_helper.dart';

DanbooruTag _tag(String name) => DanbooruTag(tag: name, count: 1);

void main() {
  group('TagSuggestionHelper.applyTag', () {
    test('replaces the word at a valid cursor', () {
      final c = TextEditingController.fromValue(
        const TextEditingValue(
          text: '1girl, smi',
          selection: TextSelection.collapsed(offset: 10),
        ),
      );
      TagSuggestionHelper.applyTag(c, _tag('smile'));
      expect(c.text, '1girl, smile, ');
      expect(c.selection.baseOffset, c.text.length);
    });

    test('with no selection it appends instead of replacing the last tag', () {
      // A programmatic `.text =` (e.g. the cascade director switching beats)
      // leaves the selection invalid; "red hair" is a finished tag and must
      // survive the insert.
      final c = TextEditingController(text: '1girl, red hair');
      expect(c.selection.isValid, isFalse);
      TagSuggestionHelper.applyTag(c, _tag('smile'));
      expect(c.text, '1girl, red hair, smile, ');
      expect(c.selection.baseOffset, c.text.length);
    });

    test('appending after a trailing comma adds no second comma', () {
      final c = TextEditingController(text: '1girl, ');
      TagSuggestionHelper.applyTag(c, _tag('smile'));
      expect(c.text, '1girl, smile, ');
    });

    test('appending to an empty field inserts the bare tag', () {
      final c = TextEditingController();
      TagSuggestionHelper.applyTag(c, _tag('smile'));
      expect(c.text, 'smile, ');
    });

    test('append mode keeps category-shortcut and character semantics', () {
      final shortcut = TextEditingController(text: 'masterpiece');
      TagSuggestionHelper.applyTag(
        shortcut,
        DanbooruTag(tag: 'artist:', count: 0, typeName: 'category_shortcut'),
      );
      expect(shortcut.text, 'masterpiece, artist:');

      final character = TextEditingController(text: 'scenery');
      TagSuggestionHelper.applyTag(
        character,
        DanbooruTag(
          tag: '[Ann]',
          count: 0,
          typeName: 'saved_character',
          expansion: '1girl, red hair',
        ),
      );
      expect(character.text, 'scenery, 1girl, red hair, ');
    });
  });
}
